export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    const data = await request.json();
    const { page, value, comment } = data;

    // DEBUG: Cek apakah koneksi DB terdeteksi
    if (!env.DB) {
      return new Response(JSON.stringify({ error: "Koneksi DB (env.DB) tidak ditemukan!" }), { 
        status: 500, headers: { 'Content-Type': 'application/json' } 
      });
    }

    if (!page || !value) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400, headers: { 'Content-Type': 'application/json' }
      });
    }

    await env.DB.prepare(
      'INSERT INTO feedback (page, value, comment, created_at) VALUES (?, ?, ?, datetime("now"))'
    ).bind(page, value, comment || '').run();

    return new Response(JSON.stringify({ ok: true }), {
      status: 200, headers: { 'Content-Type': 'application/json' }
    });
  } catch (err) {
    // DEBUG: Tampilkan pesan error asli
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { 'Content-Type': 'application/json' }
    });
  }
}
