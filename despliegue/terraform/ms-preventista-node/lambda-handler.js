const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'ms-preventista',
  brokers: ['pkc-619z3.us-east1.gcp.confluent.cloud:9092'],
  ssl: true,
  sasl: {
    mechanism: 'plain',
    username: process.env.KAFKA_USERNAME,
    password: process.env.KAFKA_PASSWORD
  }
});

const producer = kafka.producer();

exports.handler = async (event) => {
  const pedido = typeof event === 'string' ? JSON.parse(event) : event;

  console.log("📦 Pedido recibido:", pedido);

  await producer.connect();

  await producer.send({
    topic: 't_transaccion',
    messages: [
      {
        key: pedido.cliente,
        value: JSON.stringify(pedido)
      }
    ]
  });

  await producer.disconnect();

  return {
    statusCode: 200,
    body: JSON.stringify({ mensaje: "Pedido enviado a Kafka correctamente." })
  };
};
