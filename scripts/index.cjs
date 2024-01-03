const fs = require("fs");
const mongodb = require("mongodb");

const APP_URL = process.env.APP_URL || "http://localhost:3000";
const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017";
const INPUT_FILE = process.env.INPUT_FILE;
const OUTPUT_DIR = process.env.OUTPUT_DIR;

const userPayload = {
  email: "user@localhost",
  password: "123456",
  username: "user",
};

const workPayload = {
  address: "mongo",
  authentication: { authMechanism: "SCRAM-SHA-1" },
  collectionName: "testCollection",
  databaseName: "testDatabase",
  port: "27017",
};

const singleObjParse = (text) => {
  try {
    const jsonData = JSON.parse(text);
    delete jsonData["_id"];
    return jsonData;
  } catch (e) {}
};

const multiObjParse = (text) => {
  return text
    .split("\n")
    .map(singleObjParse)
    .filter((item) => item);
};

async function initDb() {
  if (INPUT_FILE === undefined) {
    return;
  }

  // Load all json files under the directory into same collection
  const client = new mongodb.MongoClient(MONGODB_URI);
  await client.connect();

  // Initialize the database
  const testDb = client.db(workPayload["databaseName"]);
  await testDb.dropCollection(workPayload["collectionName"]);
  let testCollection = testDb.collection(workPayload["collectionName"]);

  const file = fs.readFileSync(INPUT_FILE).toString();
  const lines = multiObjParse(file);
  if (lines.length !== 0) {
    await testCollection.insertMany(lines);
  }

  await client.close();
}

async function postUserRegister() {
  const status = await fetch(APP_URL + "/api/register", {
    method: "POST",
    body: JSON.stringify(userPayload),
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  }).then((response) => response.status);
  console.assert(status === 200 || status === 400);
}

async function postUserLogin() {
  const token = await fetch(APP_URL + "/api/login", {
    method: "POST",
    body: JSON.stringify({
      email: userPayload["email"],
      password: userPayload["password"],
    }),
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  })
    .then((response) => response.json())
    .then((json) => json["token"]);
  console.assert(token);
  return token;
}

async function postBatchJob(token) {
  const batchId = await fetch(APP_URL + "/api/batch/rawschema/steps/all", {
    method: "POST",
    body: JSON.stringify(workPayload),
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
  })
    .then((response) => response.json())
    .then((json) => json["batchId"]);
  console.assert(batchId);
  return batchId;
}

async function getBatchInfo(batchId, token) {
  const batchInfo = await fetch(APP_URL + `/api/batch/${batchId}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  }).then((response) => response.json());
  return batchInfo;
}

async function getJsonSchema(batchId, token) {
  const jsonSchema = await fetch(
    APP_URL + `/api/batch/jsonschema/generate/${batchId}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  ).then((response) => response.json());
  return jsonSchema;
}

initDb()
  .then(postUserRegister)
  .then(postUserLogin)
  .then(async (token) => {
    const batchId = await postBatchJob(token);
    const batchInfo = await getBatchInfo(batchId, token);
    const jsonSchema = await getJsonSchema(batchId, token);

    console.log(batchId);
    if (OUTPUT_DIR !== undefined) {
      fs.writeFileSync(
        OUTPUT_DIR + `/batchInfo_${batchId}.json`,
        JSON.stringify(batchInfo, null, 2)
      );
      fs.writeFileSync(
        OUTPUT_DIR + `/jsonSchema_${batchId}.json`,
        JSON.stringify(jsonSchema, null, 2)
      );
    }
  })
  .catch((err) => console.log(err));
