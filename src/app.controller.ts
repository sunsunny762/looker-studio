import { Controller, Get, Ip, Param } from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { UtilitiesService } from './utilities/utilities.service';
import { NotificationsService } from './notifications/notifications.service';

@Controller()
export class AppController {
  constructor(
    private readonly utilitiesService: UtilitiesService,
    private readonly moduleRef: ModuleRef
  ) {}

  @Get("keepalive")
  getKeepAlive(@Ip() ip: any): any {
    return {
      message: "Service running",
      client: ip,
      date: this.utilitiesService.now
    }
  }

  @Get('/test/broadcast-blue-award/:count')
  async testBroadcast(@Param('count') count: string) {
      const notificationsService = this.moduleRef.get(NotificationsService, { strict: false });
      await notificationsService.broadcastBlueAwardCount(parseInt(count));
    return { success: true, count: parseInt(count) };

  }
}

