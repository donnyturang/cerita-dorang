export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    const data = await request.json();
    const { page, value, comment } = data;

    if (!page || !value) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Simpan ke D1 (jika DB binding tersedia)
    if (env.DB) {
      await env.DB.prepare(
        'INSERT INTO feedback (page, value, comment, created_at) VALUES (?, ?, ?, datetime("now"))'
      ).bind(page, value, comment || '').run();
    }

    // Selalu return 200 (user tidak perlu tahu detail)
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err) {
    // Jangan expose error ke client
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
