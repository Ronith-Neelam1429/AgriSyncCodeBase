const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const tf = require("@tensorflow/tfjs-node");
const fs = require("fs-extra");
const path = require("path");

initializeApp();
const storage = getStorage();
const bucket = storage.bucket("gs://agrisync-9f9e5.firebasestorage.app");
let model;
let metadata;

async function loadModel() {
  if (model) return model;

  const tempDir = path.join("/tmp", "model");
  await fs.ensureDir(tempDir);

  const modelFiles = [
    "ai-models/plant-disease-model/model.json",
    "ai-models/plant-disease-model/weights.bin",
    "ai-models/plant-disease-model/metadata.json" // Add metadata.json if needed
  ];

  // Add error handling for downloads
  await Promise.all(
    modelFiles.map(async (filePath) => {
      try {
        const file = bucket.file(filePath);
        const destination = path.join(tempDir, path.basename(filePath));
        await file.download({ destination });
        console.log(`✅ Downloaded: ${filePath}`);
      } catch (error) {
        console.error(`❌ Failed to download ${filePath}:`, error);
        throw error;
      }
    })
  );
  const filesInTemp = await fs.readdir(tempDir);
  console.log("Files in /tmp/model:", filesInTemp);

  // Verify files exist
  const modelJsonPath = path.join(tempDir, "model.json");
  if (!(await fs.pathExists(modelJsonPath))) {
    throw new Error("model.json not found after download");
  }

  model = await tf.loadLayersModel(`file://${modelJsonPath}`);
  const metadataPath = path.join(tempDir, "metadata.json");
  if (await fs.pathExists(metadataPath)) {
    metadata = await fs.readJson(metadataPath);
    console.log("✅ Loaded metadata labels:", metadata.labels);
  } else {
    console.warn("⚠️ metadata.json not found");
  }

  return model;
}

function preprocessImage(buffer) {
  return tf.tidy(() => {
    const image = tf.node.decodeImage(buffer, 3);
    const resized = tf.image.resizeBilinear(image, [224, 224]);
    const normalized = resized.div(255.0);
    return normalized.expandDims(0);
  });
}

exports.predictImage = onRequest({ timeoutSeconds: 60, memory: "2GB" }, async (req, res) => {
  try {
    if (req.method !== "POST") throw new Error("Method not allowed");

    const { image } = req.body;
    if (!image) throw new Error("No image provided");

    await loadModel();
    const imageBuffer = Buffer.from(image, "base64");
    const tensor = preprocessImage(imageBuffer);
    const predictions = await model.predict(tensor).data();

    const [mature, overMature] = Array.from(predictions);
    res.json({
      predictions: [mature, overMature],
      label: metadata?.labels?.[mature > overMature ? 0 : 1] || // Use metadata if available
        (mature > overMature ? "Mature" : "Over Mature"), // Fallback
      confidence: (Math.max(mature, overMature) * 100).toFixed(1)
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

exports.uploadImageChunk = onRequest(async (req, res) => {
  try {
    console.log("Request received for uploadImageChunk");
    
    // Verify bucket exists
    if (!bucket) {
      console.error("Storage bucket not initialized properly");
      return res.status(500).json({ error: "Storage not configured correctly" });
    }
    
    // Log bucket name for debugging
    console.log("Using bucket:", bucket.name);
    
    const { sessionId, chunkIndex, chunk } = req.body;
    
    if (!sessionId || chunkIndex === undefined || !chunk) {
      return res.status(400).json({ error: "Missing required parameters" });
    }
    
    const filePath = `temp/${sessionId}/${chunkIndex}`;
    console.log(`Saving to path: ${filePath}`);
    
    const file = bucket.file(filePath);
    await file.save(Buffer.from(chunk, "base64"), {
      metadata: { contentType: "application/octet-stream" },
    });
    
    res.json({ success: true });
    
  } catch (error) {
    console.error("Error in uploadImageChunk:", error);
    res.status(500).json({ error: error.message });
  }
});

exports.processSessionImage = onRequest({ timeoutSeconds: 90, memory: "4GB" }, async (req, res) => {
  try {
    const { sessionId } = req.body;
    const [files] = await bucket.getFiles({ prefix: `temp/${sessionId}/` });

    const chunks = await Promise.all(
      files.sort((a, b) => a.name.localeCompare(b.name))
        .map(file => file.download().then(data => data[0]))
    );

    const imageBuffer = Buffer.concat(chunks);
    await Promise.all(files.map(file => file.delete()));

    await loadModel();
    const tensor = preprocessImage(imageBuffer);
    const predictions = await model.predict(tensor).data();

    const [mature, overMature] = Array.from(predictions);
    res.json({
      predictions: [mature, overMature],
      label: mature > overMature ? "Mature" : "Over Mature",
      confidence: (Math.max(mature, overMature) * 100).toFixed(1)
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});