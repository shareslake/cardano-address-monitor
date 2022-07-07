const createSubscriber = require('pg-listen');
const fs = require('fs');
const Config = JSON.parse(fs.readFileSync("./config"));

const subscriber = createSubscriber({ connectionString: Config.databaseURL })

subscriber.notifications.on(Config.channel, (payload) => {
  // Payload as passed to subscriber.notify() (see below)
  console.log("Received notification:", payload)
})

subscriber.events.on("error", (error) => {
  console.error("Fatal database connection error:", error)
  process.exit(1)
})

process.on("exit", () => {
  subscriber.close()
})

async function connect () {
  await subscriber.connect();
  await subscriber.listenTo(Config.channel);
  console.log("Listening...");
}

connect();
