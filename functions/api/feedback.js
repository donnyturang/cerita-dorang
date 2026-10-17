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

    await env.DB.prepare(
      'INSERT INTO feedback (page, value, comment, created_at) VALUES (?, ?, ?, datetime("now"))'
    ).bind(page, value, comment || '').run();

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err) {
    // Catat error di log Cloudflare untuk keperluan maintenance
    console.error("D1 Insert Error:", err);
    
    // Tetap kembalikan status 200 ke pengunjung agar tidak panik
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
