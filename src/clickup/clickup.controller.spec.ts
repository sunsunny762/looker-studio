import { Test, TestingModule } from '@nestjs/testing';
import { ClickupController } from './clickup.controller';
import { ClickUpService } from './clickup.service';
import { DatabaseService } from '../database';

describe('ClickupController', () => {
  let controller: ClickupController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ClickupController],
      providers: [ClickUpService, DatabaseService],
    }).compile();

    controller = module.get<ClickupController>(ClickupController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
