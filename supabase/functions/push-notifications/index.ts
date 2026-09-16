import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { JWT } from "https://esm.sh/google-auth-library@9"

interface NotificationPayload {
  record?: Record<string, unknown>
  old_record?: Record<string, unknown>
  table?: string
  type?: string
}

function parseServiceAccount(raw: string) {
  const text = raw.trim()
  if (!text) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT is empty")
  }

  let serviceAccount: Record<string, unknown>
  try {
    serviceAccount = JSON.parse(text)
  } catch (error) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT is not valid JSON: ${error}`)
  }

  if (typeof serviceAccount === "string") {
    serviceAccount = JSON.parse(serviceAccount) as Record<string, unknown>
  }

  const projectId = String(serviceAccount.project_id ?? "")
  const clientEmail = String(serviceAccount.client_email ?? "")
  const privateKey = String(serviceAccount.private_key ?? "")

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT must contain project_id, client_email, and private_key")
  }

  return {
    projectId,
    clientEmail,
    privateKey: privateKey.replace(/\\n/g, "\n"),
  }
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Only POST is allowed" }, 405)
    }

    let payload: NotificationPayload
    try {
      payload = await req.json()
    } catch {
      return jsonResponse({ error: "Request body is not valid JSON" }, 400)
    }

    const record = payload.record ?? {}
    const table = payload.table ?? ""
    const type = payload.type ?? ""

    if (type !== "INSERT" && type !== "UPDATE") {
      return jsonResponse({ message: "Only INSERT and UPDATE events are handled" })
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Supabase server environment variables are missing")
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)

    let tokens: string[] = []
    let title = ""
    let body = ""
    let collapseTag = ""
    let data: Record<string, string> = {}

    // Case 1: General Notifications (from notifications table)
    if (table === "notifications") {
      title = String(record.title ?? "إشعار جديد")
      body = String(record.body ?? "")
      const notifId = String(record.id ?? "")
      collapseTag = notifId ? `notification_${notifId}` : "notification_general"
      data = {
        type: "notification",
        id: notifId,
        title,
        body,
      }

      let query = supabase.from("profiles").select("fcm_token").not("fcm_token", "is", null)

      if (record.target_role && record.target_role !== "all") {
        query = query.eq("role", String(record.target_role))
      }

      const { data: profiles, error } = await query
      if (error) throw error

      tokens = (profiles ?? [])
        .map((p) => String(p.fcm_token ?? "").trim())
        .filter(Boolean)

    // Case 2: Chat Messages (from messages table)
    } else if (table === "messages") {
      const senderId = String(record.sender_id ?? "")
      const receiverId = String(record.receiver_id ?? "")
      const chatId = String(record.chat_id ?? "")

      const [{ data: sender, error: senderError }, { data: receiver, error: receiverError }] =
        await Promise.all([
          supabase.from("profiles").select("full_name, role").eq("id", senderId).maybeSingle(),
          supabase.from("profiles").select("fcm_token").eq("id", receiverId).maybeSingle(),
        ])

      if (senderError) throw senderError
      if (receiverError) throw receiverError

      const senderName = String(sender?.full_name ?? "رسالة جديدة")
      const senderRole = String(sender?.role ?? "student")
      title = senderName
      body = String(record.text ?? "أرسل لك ملفاً")
      
      // نستخدم معرف المحادثة أو المرسل لدمج واستبدال الإشعارات المتكررة
      collapseTag = `chat_${chatId || senderId}`

      data = {
        type: "chat",
        chatId,
        senderId,
        senderName,
        senderRole,
        title,
        body,
      }

      const token = String(receiver?.fcm_token ?? "").trim()
      if (token) {
        tokens = [token]
      }

    // Case 3: Student Uploaded Achievement -> Notify Teacher (daily_records INSERT)
    } else if (table === "daily_records" && type === "INSERT") {
      const studentId = String(record.student_id ?? "")
      const hifzContent = String(record.hifz_content ?? "")
      const revisionContent = String(record.revision_content ?? "")

      // 1. Get student name
      const { data: studentProfile } = await supabase
        .from("profiles")
        .select("full_name")
        .eq("id", studentId)
        .maybeSingle()

      const studentName = String(studentProfile?.full_name ?? "أحد الطلاب")

      // 2. Find circle for this student and the teacher's profile
      const { data: membership } = await supabase
        .from("circle_members")
        .select("circle_id, circles(teacher_id)")
        .eq("student_id", studentId)
        .maybeSingle()

      let teacherId = ""
      if (membership && membership.circles) {
        const circleData = Array.isArray(membership.circles) ? membership.circles[0] : membership.circles
        teacherId = String((circleData as Record<string, unknown>)?.teacher_id ?? "")
      }

      if (teacherId) {
        const { data: teacherProfile } = await supabase
          .from("profiles")
          .select("fcm_token")
          .eq("id", teacherId)
          .maybeSingle()

        const tToken = String(teacherProfile?.fcm_token ?? "").trim()
        if (tToken) tokens = [tToken]
      }

      const parts: string[] = []
      if (hifzContent) parts.push(`حفظ: ${hifzContent}`)
      if (revisionContent) parts.push(`مراجعة: ${revisionContent}`)

      title = `📖 إنجاز جديد من ${studentName}`
      body = parts.join(" | ") || "قام برفع إنجازه اليومي في الحلقة"
      collapseTag = `achievement_${studentId}`

      data = {
        type: "achievement",
        studentId,
        recordId: String(record.id ?? ""),
        title,
        body,
      }

    // Case 4: Teacher Evaluated/Reviewed Achievement -> Notify Student (daily_records UPDATE)
    } else if (table === "daily_records" && type === "UPDATE") {
      const studentId = String(record.student_id ?? "")
      const newStatus = String(record.status ?? "")
      const teacherNotes = String(record.teacher_notes ?? "")

      // Only notify if status changed from pending or if there is a review
      if (!newStatus || newStatus === "pending") {
        return jsonResponse({ message: "Status is pending, no notification needed" })
      }

      const statusMap: Record<string, string> = {
        approved: "✅ ممتاز / مكتمل",
        good: "👍 جيد",
        needs_improvement: "📝 يحتاج تحسين ومراجعة",
        rejected: "❌ لم يتم الاجتياز",
      }

      const statusText = statusMap[newStatus] ?? newStatus

      const { data: studentProfile, error: studentError } = await supabase
        .from("profiles")
        .select("fcm_token, full_name")
        .eq("id", studentId)
        .maybeSingle()

      if (studentError) throw studentError

      title = `🎓 قام المعلم بتقييم إنجازك (${statusText})`
      body = teacherNotes ? `ملاحظات المعلم: ${teacherNotes}` : "تم مراجعة وتقييم إنجازك اليومي بنجاح"
      collapseTag = `review_${studentId}`

      data = {
        type: "review",
        studentId,
        recordId: String(record.id ?? ""),
        status: newStatus,
        title,
        body,
      }

      const token = String(studentProfile?.fcm_token ?? "").trim()
      if (token) {
        tokens = [token]
      }

    } else {
      return jsonResponse({ message: `Unsupported table or event: ${table}/${type}` }, 200)
    }

    tokens = [...new Set(tokens)]

    if (tokens.length === 0) {
      return jsonResponse({ message: "No valid FCM tokens to send to", table, type })
    }

    const serviceAccount = parseServiceAccount(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "")
    const jwt = new JWT({
      email: serviceAccount.clientEmail,
      key: serviceAccount.privateKey,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    })

    const { token: accessToken } = await jwt.getAccessToken()
    if (!accessToken) {
      throw new Error("Could not obtain Firebase access token")
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.projectId}/messages:send`

    const results = await Promise.all(
      tokens.map(async (token) => {
        const message = {
          message: {
            token,
            notification: {
              title,
              body,
            },
            data,
            android: {
              priority: "high",
              ttl: "3600s",
              collapse_key: collapseTag || undefined,
              notification: {
                sound: "default",
                channel_id: "high_importance_channel",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                tag: collapseTag || undefined,
              },
            },
            apns: {
              headers: {
                "apns-priority": "10",
                ...(collapseTag ? { "apns-collapse-id": collapseTag } : {}),
              },
              payload: {
                aps: {
                  alert: {
                    title,
                    body,
                  },
                  sound: "default",
                  badge: 1,
                  "content-available": 1,
                },
              },
            },
          },
        }

        const response = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(message),
        })

        const responseText = await response.text()
        let responseBody: unknown = responseText
        try {
          responseBody = JSON.parse(responseText)
        } catch {
          // keep as text
        }

        return {
          tokenSuffix: token.slice(-8),
          ok: response.ok,
          status: response.status,
          response: responseBody,
        }
      })
    )

    const failed = results.filter((r) => !r.ok)

    return jsonResponse(
      {
        success: failed.length === 0,
        sent: results.length - failed.length,
        failed: failed.length,
        results,
      },
      failed.length === results.length ? 502 : 200
    )
  } catch (error) {
    console.error("Error sending notification:", error)
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500
    )
  }
})
