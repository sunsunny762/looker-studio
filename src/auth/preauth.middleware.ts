import { Injectable, NestMiddleware } from '@nestjs/common';
import { FirebaseService } from '../firebase.service';
import { UtilitiesService } from '../utilities/utilities.service';
import { ApplicationUser, DecodedUserToken } from '../account/model';

@Injectable()
export class PreauthMiddleWare implements NestMiddleware {

    constructor(private firebaseService: FirebaseService, private utilitiesService: UtilitiesService) { }

    async use(req: any, res: any, next: () => void) {
        const user = await this._extractUser(req, true);
        if (!user) {
            PreauthMiddleWare.accessDenied(req, res);
        } else {
            req["user"] = user;
            next();
        }
    }

    private static accessDenied(req: any, res: any) {
        res.status(403).json({
            statusCode: 403,
            timestamp: new Date().toISOString(),
            clientIp: req.ip,
            path: req.url,
            message: 'Access denied',
        });
    }

    private async _extractUser(request: any, asUser: boolean = false): Promise<ApplicationUser | DecodedUserToken | undefined> {
        const token = request.headers.authorization?.replace('Bearer ', '');
        const decodedToken = await this.firebaseService.verifyIdToken(token);
        if (!decodedToken) {
            return undefined;
        }
        return asUser
            ? this.firebaseService.decodedUserTokenAsUser(decodedToken)
            : decodedToken;
    }
}
