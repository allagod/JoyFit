import { PlanTask } from "../bean/PlanTask";
import { WorkoutPlanService } from "./WorkoutPlanService";
import { cloudDatabase } from "@kit.CloudFoundationKit";
import { WorkoutPlan } from "../bean/WorkoutPlan";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { PlanAction } from "../bean/PlanAction";
import { action } from "../model/action";
import { Action } from "../bean/Action";
import { WorkoutRecord } from "../bean/WorkoutRecord";

export class PlanTaskService {
  private static instance: PlanTaskService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  // 私有构造函数（单例）
  private constructor() {}

  // 获取单例实例
  public static getInstance(): PlanTaskService {
    if (!PlanTaskService.instance) {
      PlanTaskService.instance = new PlanTaskService();
    }
    return PlanTaskService.instance;
  }

  // 判断传入的日期是否为今天
  private isToday(date: Date): boolean {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfTomorrow = startOfToday + 24 * 60 * 60 * 1000;
    const targetTime = date.getTime();
    return targetTime >= startOfToday && targetTime < startOfTomorrow;
  }

  // 获取当天的训练计划任务
  public async getTodayTasks(userID: string): Promise<WorkoutPlan[]> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID).and().equalTo('TaskType', 'workout');

    const rawTasks: PlanTask[] = await this.agcDataBase.query(condition);

    // 过滤出执行日期为今天的任务
    const todayTasks: PlanTask[] = rawTasks.filter(task =>
      task.ExecutedDate && this.isToday(task.ExecutedDate)
    );

    const result: WorkoutPlan[] = [];
    for (let task of todayTasks) {
      const planQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
      planQuery.equalTo('PlanID', task.PlanID);
      const plans = await this.agcDataBase.query(planQuery);
      const plan = plans.pop();
      if (plan) result.push(plan);
    }
    return result;
  }

  // 根据计划ID获取所有动作信息（带详情）
  public async getActionsByPlanID(planID: string) {
    const condition = new cloudDatabase.DatabaseQuery(PlanAction);
    condition.equalTo('PlanID', planID);
    const planActions: PlanAction[] = await this.agcDataBase.query(condition);

    const result: action[] = [];
    for (let planAction of planActions) {
      const actionQuery = new cloudDatabase.DatabaseQuery(Action);
      actionQuery.equalTo('ActionID', planAction.ActionID);
      const goalActions: Action[] = await this.agcDataBase.query(actionQuery);
      const actionRes = goalActions.pop();

      if (actionRes) {
        const merged = action.createFromAction(actionRes, planAction);
        if (merged) result.push(merged);
      }
    }
    return result;
  }

  // 标记任务为已完成
  public async finishTask(taskID: string): Promise<boolean> {
    try {
      const query = new cloudDatabase.DatabaseQuery(PlanTask);
      query.equalTo('TaskID', taskID);
      const tasks = await this.agcDataBase.query(query);
      const task = tasks.pop();
      if (task) {
        task.State = "Completed";
        await this.agcDataBase.upsert(task);
      }
      return true;
    } catch (err) {
      console.info(`Failed in completing a plan: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 标记任务为已放弃
  public async abandonTask(taskID: string): Promise<boolean> {
    try {
      const query = new cloudDatabase.DatabaseQuery(PlanTask);
      query.equalTo('TaskID', taskID);
      const tasks = await this.agcDataBase.query(query);
      const task = tasks.pop();
      if (task) {
        task.State = "Abandoned";
        await this.agcDataBase.upsert(task);
      }
      return true;
    } catch (err) {
      console.info(`Failed in abandoning a plan: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 上传用户的训练感受记录
  public async uploadFeelings(record: WorkoutRecord): Promise<boolean> {
    try {
      await this.agcDataBase.upsert(record);
      return true;
    } catch (err) {
      console.info(`Failed in uploading a record: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 分页获取任务历史，可指定状态
  public async getTaskHistory(userID: string, stateFilter: string[] = [], limit: number = 10, offset: number = 0): Promise<PlanTask[]> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID);
    if (stateFilter.length > 0) {
      condition.in('State', stateFilter);
    }
    condition.limit(limit).offset(offset);
    return await this.agcDataBase.query(condition);
  }

  // 获取已完成任务总数
  public async getCompletedTaskCount(userID: string): Promise<number> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID).and().equalTo('State', 'Completed');
    const results: PlanTask[] = await this.agcDataBase.query(condition);
    return results.length;
  }

  // 按日期范围查询任务
  public async getTasksByDateRange(userID: string, start: Date, end: Date): Promise<PlanTask[]> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID)
             .and()
             .greaterThanOrEqualTo('ExecutedDate', start)
             .and()
             .lessThanOrEqualTo('ExecutedDate', end);
    return await this.agcDataBase.query(condition);
  }

  // 删除指定任务
  public async deleteTask(taskID: string): Promise<boolean> {
    try {
      const condition = new cloudDatabase.DatabaseQuery(PlanTask);
      condition.equalTo('TaskID', taskID);
      const tasks = await this.agcDataBase.query(condition);
      const task = tasks.pop();
      if (task) {
        await this.agcDataBase.delete(task);
      }
      return true;
    } catch (err) {
      console.error(`Failed to delete task: ${JSON.stringify(err)}`);
      return false;
    }
  }

  // 获取明天的任务列表（用于提醒或提前准备）
  public async getTomorrowTasks(userID: string): Promise<WorkoutPlan[]> {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const start = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID)
             .and()
             .greaterThanOrEqualTo('ExecutedDate', start)
             .and()
             .lessThan('ExecutedDate', end);

    const taskArray: PlanTask[] = await this.agcDataBase.query(condition);
    const result: WorkoutPlan[] = [];

    for (let task of taskArray) {
      const planQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
      planQuery.equalTo('PlanID', task.PlanID);
      const planArray: WorkoutPlan[] = await this.agcDataBase.query(planQuery);
      const plan = planArray.pop();
      if (plan) result.push(plan);
    }

    return result;
  }

  // 模糊搜索计划名称（需要数据库支持 contains 查询）
  public async searchPlansByName(userID: string, keyword: string): Promise<WorkoutPlan[]> {
    const condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('UserID', userID)
             .and()
             .contains('PlanName', keyword);
    return await this.agcDataBase.query(condition);
  }
}
