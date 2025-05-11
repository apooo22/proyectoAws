exports.handler = async (event) => {
  try {
    console.log("Evento recibido:", JSON.stringify(event));

    const claims = event.requestContext?.authorizer?.claims;
    const groups = claims?.["cognito:groups"] || [];

    if (groups.includes("admin")) {
      return {
        statusCode: 200,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "Content-Type,Authorization",
          "Access-Control-Allow-Methods": "GET,OPTIONS"
        },
        body: JSON.stringify({ message: "✅ Acceso concedido a /admin" }),
      };
    }

    return {
      statusCode: 403,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "GET,OPTIONS"
      },
      body: JSON.stringify({ message: "⛔ Acceso denegado (no es admin)" }),
    };
  } catch (err) {
    console.error("Error interno:", err);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "GET,OPTIONS"
      },
      body: JSON.stringify({ error: "Error interno del servidor" }),
    };
  }
};
