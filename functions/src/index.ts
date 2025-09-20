import * as functions from "firebase-functions";
import * as jwt from "jsonwebtoken";
import "dotenv/config";

// Read VideoSDK creds from Firebase config
const API_KEY = process.env.VIDEOSDK_KEY || "";
const SECRET = process.env.VIDEOSDK_SECRET || "";

if (!API_KEY || !SECRET) {
  console.error("❌ VideoSDK API key/secret missing. Run: firebase functions:config:set ...");
}

interface TokenRequest {
  as?: string;
  roomId?: string;
}

export const getVideoSDKToken = functions.https.onCall(
  (request: functions.https.CallableRequest<TokenRequest>) => {
    const roleParam = request.data?.as === "host" ? "host" : "viewer";
    const roomId =
      typeof request.data?.roomId === "string" ? request.data.roomId : undefined;

    // Permissions based on role
    const permissions =
      roleParam === "host" ? ["allow_join", "allow_mod"] : ["allow_join"];

    const payload: jwt.JwtPayload = {
      apikey: API_KEY,
      permissions,
      version: 2, // required by VideoSDK v2
      roles: ["rtc"],
      ...(roomId ? { roomId } : {}),
    };

    const options: jwt.SignOptions = {
      expiresIn: "120m", // token valid for 2 hours
      algorithm: "HS256",
    };

    const token = jwt.sign(payload, SECRET, options);

    return { token };
  }
);
