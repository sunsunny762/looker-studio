import { Injectable, NestMiddleware } from "@nestjs/common";

@Injectable()
export class ServerBasicAuthMiddleWare implements NestMiddleware {
  async use(req: any, res: any, next: () => void) {
    // If the request carries a Bearer token it is a user-authenticated request
    // already handled by PreauthMiddleWare — skip server-to-server Basic auth.
    const authHeader: string | undefined = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return next();
    }

    const authed = await this._extractUser(req);
    if (!authed) {
      return ServerBasicAuthMiddleWare.accessDenied(
        req,
        res,
        "app id set not provided"
      );
    }
    const appid = authed[0];
    const appkey = authed[1];

    // TODO Securely store app ids and keys in the db. Look up by the supplied app id
    // and if found, check the key matches to allow us to accept the auth request.
    const requiredid = process.env.EXTERNAL_APP_ID;
    const requiredkey = process.env.EXTERNAL_APP_KEY;
    if (!requiredid || !requiredkey) {
      return ServerBasicAuthMiddleWare.accessDenied(
        req,
        res,
        "app id exchange inactive"
      );
    }
    if (requiredid != appid || requiredkey != appkey) {
      return ServerBasicAuthMiddleWare.accessDenied(
        req,
        res,
        "invalid app id set provided"
      );
    }
    req.appid = appid;
    return next();
  }

  private static accessDenied(req: any, res: any, reason: string) {
    res.status(403).json({
      statusCode: 403,
      timestamp: new Date().toISOString(),
      clientIp: req.ip,
      path: req.url,
      message: `Access denied - ${reason}`,
    });
  }

  private async _extractUser(request: any): Promise<any | undefined> {
    const auth = request.headers.authorization?.replace("Basic ", "");
    try {
      const credentials = Buffer.from(auth, "base64").toString("ascii");
      const userAndPass = credentials.split(":");
      return userAndPass;
    } catch {
      return undefined;
    }
  }
}
