import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { record } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' 
    )

    const filesToDelete: string[] = [];

    // هنا استبدلنا chat_media بـ chat_attachments بناءً على الصورة
    const bucketName = 'chat_attachments';

    if (record?.audio_url) {
      const path = record.audio_url.split(`${bucketName}/`)[1];
      if (path) filesToDelete.push(path);
    }
    if (record?.image_url) {
      const path = record.image_url.split(`${bucketName}/`)[1];
      if (path) filesToDelete.push(path);
    }

    if (filesToDelete.length > 0) {
      // الحذف من الـ Bucket الصحيح
      const { data, error } = await supabase.storage.from(bucketName).remove(filesToDelete)
      if (error) throw error
    }

    return new Response(JSON.stringify({ success: true, deleted: filesToDelete }), { 
      headers: { "Content-Type": "application/json" },
      status: 200 
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { 
      headers: { "Content-Type": "application/json" },
      status: 400 
    })
  }
})