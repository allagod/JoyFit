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



/**
 * 批量将指定任务列表标记为已完成状态
 * @param taskIDs - 任务ID数组
 * @returns 操作是否成功，全部任务更新成功返回 true，出现异常返回 false
 */
public async finishTasks(taskIDs: string[]): Promise<boolean> {
  try {
    for (const taskID of taskIDs) {
      const query = new cloudDatabase.DatabaseQuery(PlanTask);
      query.equalTo('TaskID', taskID);
      const tasks = await this.agcDataBase.query(query);
      const task = tasks.pop();
      if (task) {
        task.State = "Completed";
        await this.agcDataBase.upsert(task);
      }
    }
    return true;
  } catch (err) {
    console.error(`Failed batch complete tasks: ${JSON.stringify(err)}`);
    return false;
  }
}

/**
 * 批量将指定任务列表标记为已放弃状态
 * @param taskIDs - 任务ID数组
 * @returns 操作是否成功，全部任务更新成功返回 true，出现异常返回 false
 */
public async abandonTasks(taskIDs: string[]): Promise<boolean> {
  try {
    for (const taskID of taskIDs) {
      const query = new cloudDatabase.DatabaseQuery(PlanTask);
      query.equalTo('TaskID', taskID);
      const tasks = await this.agcDataBase.query(query);
      const task = tasks.pop();
      if (task) {
        task.State = "Abandoned";
        await this.agcDataBase.upsert(task);
      }
    }
    return true;
  } catch (err) {
    console.error(`Failed batch abandon tasks: ${JSON.stringify(err)}`);
    return false;
  }
}

/**
 * 根据计划ID查询对应的所有任务，可选择按状态过滤
 * @param planID - 计划ID
 * @param states - 状态字符串数组（可选），不传则查询所有状态
 * @returns 满足条件的任务列表
 */
public async getTasksByPlanID(planID: string, states: string[] = []): Promise<PlanTask[]> {
  const condition = new cloudDatabase.DatabaseQuery(PlanTask);
  condition.equalTo('PlanID', planID);
  if (states.length > 0) {
    condition.in('State', states);
  }
  return await this.agcDataBase.query(condition);
}

/**
 * 查询指定用户所有未完成任务（状态非已完成及已放弃）
 * @param userID - 用户ID
 * @returns 该用户所有处于待完成状态的任务列表
 */
public async getPendingTasks(userID: string): Promise<PlanTask[]> {
  const condition = new cloudDatabase.DatabaseQuery(PlanTask);
  condition.equalTo('UserID', userID);
  condition.notEqualTo('State', 'Completed').and().notEqualTo('State', 'Abandoned');
  return await this.agcDataBase.query(condition);
}

/**
 * 根据用户ID和具体日期查询当天所有任务
 * @param userID - 用户ID
 * @param date - 指定查询的日期
 * @returns 当天执行的任务列表
 */
public async getTasksByDate(userID: string, date: Date): Promise<PlanTask[]> {
  const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

  const condition = new cloudDatabase.DatabaseQuery(PlanTask);
  condition.equalTo('UserID', userID)
           .and()
           .greaterThanOrEqualTo('ExecutedDate', start)
           .and()
           .lessThan('ExecutedDate', end);

  return await this.agcDataBase.query(condition);
}

/**
 * 获取用户的训练记录，并附带对应的任务信息（若存在）
 * @param userID - 用户ID
 * @param limit - 返回记录条数限制，默认10条
 * @param offset - 记录偏移量，用于分页，默认0
 * @returns 数组，包含记录和对应任务对象
 */
public async getRecordsWithTasks(userID: string, limit: number = 10, offset: number = 0) {
  const condition = new cloudDatabase.DatabaseQuery(WorkoutRecord);
  condition.equalTo('UserID', userID);
  condition.limit(limit).offset(offset);

  const records = await this.agcDataBase.query(condition);
  const result = [];

  for (const record of records) {
    if (record.TaskID) {
      const taskQuery = new cloudDatabase.DatabaseQuery(PlanTask);
      taskQuery.equalTo('TaskID', record.TaskID);
      const tasks = await this.agcDataBase.query(taskQuery);
      const task = tasks.pop();
      result.push({ record, task });
    } else {
      result.push({ record, task: null });
    }
  }
  return result;
}

/**
 * 根据任务 ID 更新任务备注
 * @param taskID - 待更新的任务 ID
 * @param note - 备注内容
 * @returns 成功返回 true，失败返回 false
 */
public async updateTaskNote(taskID: string, note: string): Promise<boolean> {
  if (!taskID || typeof note !== 'string') {
    console.warn('Invalid parameters for updateTaskNote');
    return false;
  }

  try {
    const query = new cloudDatabase.DatabaseQuery(PlanTask);
    query.equalTo('TaskID', taskID);

    const [task] = await this.agcDataBase.query(query);
    if (!task) {
      console.warn(`No task found with TaskID: ${taskID}`);
      return false;
    }

    task.Note = note;
    await this.agcDataBase.upsert(task);
    return true;
  } catch (error) {
    console.error(`Error updating task note for TaskID ${taskID}:`, error);
    return false;
  }
}

/**
 * 获取指定用户的任务状态分布统计
 * @param userID - 用户 ID
 * @returns 一个对象，键为任务状态，值为对应状态的数量
 */
public async getTaskCountByState(userID: string): Promise<Record<string, number>> {
  if (!userID) {
    console.warn('UserID is required to get task count by state');
    return {};
  }

  const stateList = ['Pending', 'Completed', 'Abandoned', 'InProgress'];
  const result: Record<string, number> = {};

  try {
    for (const state of stateList) {
      const query = new cloudDatabase.DatabaseQuery(PlanTask);
      query.equalTo('UserID', userID).and().equalTo('State', state);

      const tasks = await this.agcDataBase.query(query);
      result[state] = tasks.length;
    }
  } catch (error) {
    console.error(`Error fetching task count by state for user ${userID}:`, error);
  }

  return result;
}

