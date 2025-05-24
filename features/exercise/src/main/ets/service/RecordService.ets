import { cloudDatabase } from "@kit.CloudFoundationKit";
import { PlanTask } from "../bean/PlanTask";
import { RunningRecord } from "../bean/RunningRecord";
import { WorkoutRecord } from "../bean/WorkoutRecord";


export class RecordService {
  private static instance: RecordService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {}

  public static getInstance(): RecordService {
    if (!RecordService.instance) {
      RecordService.instance = new RecordService();
    }
    return RecordService.instance;
  }

  // 根据用户ID、计划ID和类型获取对应的感受记录
  public async getFeelingsByPlan(userID: string, planID: string, type: string) {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const condition = new cloudDatabase.DatabaseQuery(recordClass);
    condition.equalTo('UserID', userID).and().equalTo('PlanID', planID);
    const result = await this.agcDataBase.query(condition);
    return result;
  }

  // 获取用户在某个计划下的任务记录
  public async getRecords(userID: string, planID: string, type: string) {
    const taskType = this.getTaskType(type);
    if (!taskType) return [];

    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID).and().equalTo('PlanID', planID).and().equalTo('TaskType', taskType);
    const result = await this.agcDataBase.query(condition);
    return result;
  }

  // 根据类型返回对应的数据模型
  private getRecordModel(type: string) {
    if (type === 'workout') return WorkoutRecord;
    if (type === 'running') return RunningRecord;
    return null;
  }

  // 获取任务类型字段
  private getTaskType(type: string) {
    if (type === 'workout' || type === 'running') return type;
    return null;
  }
}
