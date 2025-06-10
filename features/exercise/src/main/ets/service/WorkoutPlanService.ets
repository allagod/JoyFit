import {ExercisePlanService} from '../service/ExercisePlanService'
import {WorkoutPlan} from'../bean/WorkoutPlan'
import { cloudDatabase } from '@kit.CloudFoundationKit';
import { workoutPlan } from'../model/workoutPlan'
import { PlanAction } from '../bean/PlanAction';
import { action, actionInfo } from '../model/action';
import { PlanTask } from '../bean/PlanTask';
import { WorkoutRecord } from '../bean/WorkoutRecord';
import { workoutPlanBuilder } from '../model/workoutPlanBuilder';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UUIDGenerator } from 'utils';
import { Action } from '../bean/Action';

export class WorkoutPlanService extends ExercisePlanService {

  private static instance: WorkoutPlanService | null = null;

  private constructor() {
    super();
  }

  public async getActionsByPlanID(planID: string){
    let condition = new cloudDatabase.DatabaseQuery(PlanAction);
    condition.equalTo('PlanID', planID);
    const actions : PlanAction[] = await this.agcDataBase.query(condition);
    //再拼接Action表的信息
    let result: action[] =[];
    for(let planAction of actions){
      let condition = new cloudDatabase.DatabaseQuery(Action);
      condition.equalTo('ActionID', planAction.ActionID);
      const goalAction : Action[] = await this.agcDataBase.query(condition);
      let actionRes =goalAction.pop();
      if(actionRes!= undefined){
        let res = action.createFromAction(actionRes,planAction);
        if(res != null)
          result.push(res);
      }
    }
    return result;
  }

  protected getExecutionDates(startDate?: Date, endDate?: Date, daysOfWeekStr?: string): Date[] {
    const executionDates: Date[] = [];
    if(startDate!= undefined && endDate!=undefined && daysOfWeekStr!=undefined){
      const daysOfWeek = daysOfWeekStr.split('#').map(day => parseInt(day, 10));
      // 确保 daysOfWeek 是升序的，便于后续处理
      daysOfWeek.sort((a, b) => a - b);
      // 计算开始日期是星期几
      let currentDate = new Date(startDate);
      //const currentDayOfWeek = currentDate.getDay(); // Sunday - 0, Monday - 1, ..., Saturday - 6
      // 从开始日期开始，遍历到结束日期
      while (currentDate <= endDate) {
        const currentDay = currentDate.getDay(); // 当前日期的星期几
        // 如果当前星期几在用户指定的 daysOfWeek 中，就把当前日期添加到执行日期列表
        if (daysOfWeek.includes(currentDay)) {
          executionDates.push(new Date(currentDate));
        }
        // 增加一天，继续检查下一个日期
        currentDate.setDate(currentDate.getDate() + 1);
      }
    }
    return executionDates;
  }

  protected taskToBean(planID:string,userID:string,date:Date){
    let task = new PlanTask();
    task.TaskID = UUIDGenerator.getID();
    task.UserID =userID;
    task.PlanID =planID;
    task.ExecutedDate =date;
    task.State = 'Pending';
    task.TaskType ='workout';
    return task;
  }

  public static getInstance(): WorkoutPlanService{
    if (!WorkoutPlanService.instance) {
      WorkoutPlanService.instance = new WorkoutPlanService();
    }
    return  WorkoutPlanService.instance;
  }

  public createPlanBuilder(): workoutPlanBuilder {
    return new workoutPlanBuilder();
  }

  private ToBean(plan:workoutPlan){
    let planContent =new WorkoutPlan();
    planContent.PlanID = plan.PlanID;
    planContent.UserID =plan.UserID;
    planContent.PlanName =plan.PlanName;
    planContent.CoverPicture =plan.CoverPicture;
    planContent.PlanState =plan.PlanState;
    planContent.EndDate =plan.EndDate;
    planContent.DayOfWeek =plan.DayOfWeek;
    planContent.StartDate =plan.StartDate;
    planContent.RestTimeBetweenSets = plan.RestTimeBetweenSets;
    planContent.RestTimeBetweenExercises =plan.RestTimeBetweenExercises;
    planContent.TotalTime =plan.TotalTime;
    planContent.Tag = plan.Tag;
    planContent.Description =plan.Description;
    return planContent;
  }

  private planActionToBean(plan:workoutPlan,_action:actionInfo){
    let planAction = new PlanAction();
    planAction.PlanID = plan.PlanID;
    planAction.ActionID = _action.ActionID;
    planAction.Sets =_action.Sets;
    planAction.SingleSetNum =_action.SingleSetNum;
    return planAction;
  }

  public async uploadPlan(plan:workoutPlan): Promise<boolean> {
      const planContent =this.ToBean(plan);
      let targetDates =this.getExecutionDates(plan.StartDate,plan.EndDate,plan.DayOfWeek);
      let taskArr: PlanTask[] =[];
      for(let date of targetDates){
        if(plan.PlanID != undefined && plan.UserID!=undefined)
          taskArr.push(this.taskToBean(plan.PlanID,plan.UserID,date))
      }
      let planActionArr: PlanAction[] =[];
      if(plan.includedActions != undefined)
        for(let _action of plan.includedActions){
          planActionArr.push(this.planActionToBean(plan,_action));
      }
      try {
        //向PlanAction表插入记录
        await this.agcDataBase?.upsert(planActionArr)
        //向WorkoutPlan表中插入记录
        await this.agcDataBase?.upsert(planContent);
        //向PlanTask插入待办任务
        await this.agcDataBase?.upsert(taskArr);
        return true;
      } catch (err) {
        return false;
      }
  }

  private async deleteTask(planID: string){
    let condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('PlanID',planID);
    const Array: PlanTask[]= await this.agcDataBase.query(condition);
    let deleteNum = this.agcDataBase.delete(Array);
  }

  private async deletePlanAction(planID:string){
    let condition2 = new cloudDatabase.DatabaseQuery(PlanAction);
    condition2.equalTo('PlanID',planID);
    const Array2: PlanAction[]= await this.agcDataBase.query(condition2);
    let deleteNum2 = this.agcDataBase.delete(Array2);
  }


  public async deletePlan(planID: string) {
    let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('PlanID',planID);
    let res = await this.agcDataBase.query(condition);
    let num= await this.agcDataBase.delete(res);
    //hilog.info(1,'删除数量',num.toString());
    this.deleteTask(planID);
    this.deletePlanAction(planID);
  }

  public async updatePlan(plan: workoutPlan) {
    //首先删除所有之前的计划记录（先查后删）
    try{
      if(plan.PlanID != undefined)
        await this.deletePlan(plan.PlanID);
      this.uploadPlan(plan);
      //再上传一个新的计划
      return true;
    } catch (err) {
      return false;
    }
  }

  /**
 * 获取指定用户处于指定状态的所有训练计划
 * @param userID - 用户ID
 * @param state - 计划状态（如 NotStarted、InProgress、Completed、Abandoned）
 * @returns 满足条件的 WorkoutPlan 数组
 */
public async getPlansByState(userID: string, state: string): Promise<WorkoutPlan[]> {
  if (!userID || !state) {
    console.warn('Invalid input for getPlansByState');
    return [];
  }
  try {
    const query = new cloudDatabase.DatabaseQuery(WorkoutPlan)
      .equalTo('UserID', userID)
      .and()
      .equalTo('PlanState', state);
    return await this.agcDataBase.query(query);
  } catch (err) {
    console.error(`Failed to fetch plans by state: ${state}`, err);
    return [];
  }
}

/**
 * 将计划状态标记为已放弃（Abandoned）
 * @param plan - 要更新状态的计划对象
 * @returns 操作是否成功
 */
public async abandonPlan(plan: WorkoutPlan): Promise<boolean> {
  try {
    plan.PlanState = 'Abandoned';
    await this.agcDataBase.upsert(plan);
    console.info('Plan successfully marked as abandoned');
    return true;
  } catch (err) {
    console.error('Failed to abandon plan:', err);
    return false;
  }
}

/**
 * 获取指定计划下的所有任务，并按任务状态分类
 * @param planID - 计划ID
 * @returns 一个对象，包含 pending、completed 和 cancelled 三类任务数组
 */
public async getTasksGroupedByState(planID: string): Promise<{ pending: PlanTask[]; completed: PlanTask[]; cancelled: PlanTask[] }> {
  try {
    const query = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('PlanID', planID);
    const allTasks = await this.agcDataBase.query(query);
    return {
      pending: allTasks.filter(t => t.State === 'Pending'),
      completed: allTasks.filter(t => t.State === 'Completed'),
      cancelled: allTasks.filter(t => t.State === 'Cancelled'),
    };
  } catch (err) {
    console.error('Error grouping tasks by state:', err);
    return { pending: [], completed: [], cancelled: [] };
  }
}

/**
 * 将某任务标记为已完成（Completed）
 * @param taskID - 任务ID
 * @returns 操作是否成功
 */
public async markTaskAsCompleted(taskID: string): Promise<boolean> {
  try {
    const query = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('TaskID', taskID);
    const [task] = await this.agcDataBase.query(query);
    if (!task) return false;

    task.State = 'Completed';
    await this.agcDataBase.upsert(task);
    return true;
  } catch (err) {
    console.error('Failed to complete task:', err);
    return false;
  }
}

/**
 * 计算指定计划的完成进度百分比
 * @param planID - 计划ID
 * @returns 计划完成进度（百分比整数）
 */
public async calculatePlanProgress(planID: string): Promise<number> {
  try {
    const query = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('PlanID', planID);
    const tasks = await this.agcDataBase.query(query);
    if (!tasks.length) return 0;

    const completed = tasks.filter(t => t.State === 'Completed').length;
    return Math.round((completed / tasks.length) * 100);
  } catch (err) {
    console.error('Error calculating plan progress:', err);
    return 0;
  }
}

/**
 * 通过关键词搜索指定用户的训练计划（模糊匹配计划名）
 * @param userID - 用户ID
 * @param keyword - 计划名称关键字
 * @param limit - 返回条数限制
 * @param offset - 分页偏移
 * @returns 匹配到的 WorkoutPlan 数组
 */
public async searchPlans(userID: string, keyword: string, limit = 20, offset = 0): Promise<WorkoutPlan[]> {
  try {
    const query = new cloudDatabase.DatabaseQuery(WorkoutPlan)
      .equalTo('UserID', userID)
      .and()
      .contains('PlanName', keyword);
    return await this.agcDataBase.query(query, { limit, offset });
  } catch (err) {
    console.error('Plan search failed:', err);
    return [];
  }
}

/**
 * 记录用户对计划进行的某项操作（如创建、更新、放弃等）
 * @param planID - 计划ID
 * @param userID - 用户ID
 * @param operation - 操作类型描述
 * @param detail - 可选的详细说明
 */
public async logPlanAction(planID: string, userID: string, operation: string, detail = ''): Promise<void> {
  try {
    const logEntry = {
      LogID: UUIDGenerator.getID(),
      PlanID: planID,
      UserID: userID,
      Operation: operation,
      Detail: detail,
      Timestamp: new Date(),
    };
    await this.agcDataBase.upsert(logEntry);
  } catch (err) {
    console.error('Failed to log plan operation:', err);
  }
}

/**
 * 汇总用户的计划数量统计信息（各状态的数量）
 * @param userID - 用户ID
 * @returns 一个包含 NotStarted、InProgress、Completed、Abandoned 数量的对象
 */
public async summarizeUserPlans(userID: string): Promise<Record<string, number>> {
  const states = ['NotStarted', 'InProgress', 'Completed', 'Abandoned'];
  const summary: Record<string, number> = {};

  try {
    for (const state of states) {
      const query = new cloudDatabase.DatabaseQuery(WorkoutPlan)
        .equalTo('UserID', userID)
        .and()
        .equalTo('PlanState', state);
      const results = await this.agcDataBase.query(query);
      summary[state] = results.length;
    }
  } catch (err) {
    console.error('Failed to summarize user plans:', err);
  }

  return summary;
}

/**
 * 批量更新多个任务的状态（如批量标记为已取消）
 * @param taskIDs - 要更新状态的任务ID数组
 * @param newState - 新状态（如 'Cancelled'）
 * @returns 操作是否全部成功
 */
public async batchUpdateTaskStates(taskIDs: string[], newState: string): Promise<boolean> {
  try {
    for (const taskID of taskIDs) {
      const query = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('TaskID', taskID);
      const [task] = await this.agcDataBase.query(query);
      if (task) {
        task.State = newState;
        await this.agcDataBase.upsert(task);
      }
    }
    return true;
  } catch (err) {
    console.error('Failed to batch update task states:', err);
    return false;
  }
}



public async autoUpdatePlanStates(userID: string): Promise<void> {
  const now = new Date();
  const condition = new cloudDatabase.DatabaseQuery(WorkoutPlan)
    .equalTo('UserID', userID)
    .and()
    .notEqualTo('PlanState', 'Completed')
    .and()
    .notEqualTo('PlanState', 'Abandoned');

  const plans = await this.agcDataBase.query(condition);
  for (const plan of plans) {
    if (plan.StartDate && plan.EndDate) {
      if (now < plan.StartDate && plan.PlanState !== 'NotStarted') {
        plan.PlanState = 'NotStarted';
        await this.agcDataBase.upsert(plan);
      } else if (now >= plan.StartDate && now <= plan.EndDate && plan.PlanState !== 'InProgress') {
        plan.PlanState = 'InProgress';
        await this.agcDataBase.upsert(plan);
      } else if (now > plan.EndDate && plan.PlanState !== 'Completed') {
        plan.PlanState = 'Completed';
        await this.agcDataBase.upsert(plan);
      }
    }
  }
}


public async regenerateTasksForPlan(plan: workoutPlan): Promise<boolean> {
  try {
    if (!plan.PlanID) return false;
    await this.deleteTask(plan.PlanID); // 删除旧任务
    const dates = this.getExecutionDates(plan.StartDate, plan.EndDate, plan.DayOfWeek);
    const newTasks = dates.map(date => this.taskToBean(plan.PlanID!, plan.UserID!, date));
    await this.agcDataBase.upsert(newTasks);
    return true;
  } catch (err) {
    console.error('重新生成任务失败:', err);
    return false;
  }
}

public async importPlanFromJSON(jsonStr: string): Promise<boolean> {
  try {
    const data = JSON.parse(jsonStr);
    if (!data.plan) return false;

    // 先删除原计划
    if (data.plan.PlanID) {
      await this.deletePlan(data.plan.PlanID);
    }

    // 新计划
    await this.agcDataBase.upsert(data.plan);

    // 相关动作和任务
    if (Array.isArray(data.actions)) {
      await this.agcDataBase.upsert(data.actions);
    }
    if (Array.isArray(data.tasks)) {
      await this.agcDataBase.upsert(data.tasks);
    }

    return true;
  } catch (err) {
    console.error('导入计划失败:', err);
    return false;
  }
}

public async getPlanReport(planID: string) {
  const tasks = await this.agcDataBase.query(new cloudDatabase.DatabaseQuery(PlanTask).equalTo('PlanID', planID));
  if (tasks.length === 0) return null;

  const completedTasks = tasks.filter(t => t.State === 'Completed');
  const completionRate = completedTasks.length / tasks.length;

  // 假设每个任务有记录WorkoutRecord（含时间）
  const records = await this.agcDataBase.query(new cloudDatabase.DatabaseQuery(WorkoutRecord).equalTo('PlanID', planID));
  const totalTime = records.reduce((sum, r) => sum + (r.Duration || 0), 0);
  const avgTime = records.length ? totalTime / records.length : 0;

  return {
    totalTasks: tasks.length,
    completedTasks: completedTasks.length,
    completionRate,
    totalTime,
    avgTime,
  };
}

public async getUpcomingTasks(userID: string, daysAhead = 1): Promise<PlanTask[]> {
  const now = new Date();
  const futureDate = new Date();
  futureDate.setDate(now.getDate() + daysAhead);

  const condition = new cloudDatabase.DatabaseQuery(PlanTask)
    .equalTo('UserID', userID)
    .and()
    .equalTo('State', 'Pending')
    .and()
    .greaterThanOrEqualTo('ExecutedDate', now)
    .and()
    .lessThanOrEqualTo('ExecutedDate', futureDate);

  const tasks = await this.agcDataBase.query(condition);
  return tasks;
}
