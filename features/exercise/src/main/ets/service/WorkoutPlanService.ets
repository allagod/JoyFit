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

  public async getNotStartedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','NotStarted');
    const planArray: WorkoutPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  public async getCompletedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','Completed');
    const planArray: WorkoutPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  public async getInProgressPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','InProgress');
    const planArray: WorkoutPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  public async getAbandonedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','Abandoned');
    const planArray: WorkoutPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  public async abandonInProgressPlan(targetPlan:WorkoutPlan){
    try{
      targetPlan.PlanState = "Abandoned";
      await this.agcDataBase?.upsert(targetPlan);
      console.info(`Succeeded in abandoning a plan.`);
      return true;
    }
    catch(err){
      console.info(`Failed in deleting a plan: ${JSON.stringify(err)} `);
      return false;
    }
  };
}


  /**
   * 获取某计划的所有任务，按状态分类返回
   */
  public async getTasksByPlanID(planID: string): Promise<{ pending: PlanTask[], completed: PlanTask[], cancelled: PlanTask[] }> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('PlanID', planID);
    const tasks: PlanTask[] = await this.agcDataBase.query(condition);

    const pending = tasks.filter(t => t.State === 'Pending');
    const completed = tasks.filter(t => t.State === 'Completed');
    const cancelled = tasks.filter(t => t.State === 'Cancelled');

    return { pending, completed, cancelled };
  }

  /**
   * 标记某任务为完成
   */
  public async completeTask(taskID: string): Promise<boolean> {
    try {
      const condition = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('TaskID', taskID);
      const tasks: PlanTask[] = await this.agcDataBase.query(condition);
      if (tasks.length === 0) return false;

      const task = tasks[0];
      task.State = 'Completed';
      await this.agcDataBase.upsert(task);
      return true;
    } catch (err) {
      console.error('完成任务失败:', err);
      return false;
    }
  }

  /**
   * 计算计划的执行进度百分比（完成任务数/总任务数）
   */
  public async getPlanProgress(planID: string): Promise<number> {
    const condition = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('PlanID', planID);
    const tasks: PlanTask[] = await this.agcDataBase.query(condition);
    if (tasks.length === 0) return 0;

    const completedCount = tasks.filter(t => t.State === 'Completed').length;
    return Math.round((completedCount / tasks.length) * 100);
  }

  /**
   * 按关键词搜索计划名称（模糊搜索）
   */
  public async searchPlansByName(userID: string, keyword: string, limit = 20, offset = 0): Promise<WorkoutPlan[]> {
    // 注意：具体实现依赖数据库是否支持模糊搜索，这里用简单包含示意
    const condition = new cloudDatabase.DatabaseQuery(WorkoutPlan)
      .equalTo('UserID', userID)
      .and()
      .contains('PlanName', keyword); // 假设contains支持模糊搜索

    const plans = await this.agcDataBase.query(condition, { limit, offset });
    return plans;
  }

  /**
   * 记录计划操作日志（简易示例）
   */
  public async logPlanOperation(planID: string, userID: string, operation: string, detail?: string) {
    const log = {
      LogID: UUIDGenerator.getID(),
      PlanID: planID,
      UserID: userID,
      Operation: operation,
      Detail: detail || '',
      Timestamp: new Date(),
    };
    await this.agcDataBase.upsert(log);
  }

  /**
   * 查询某用户所有计划的统计数据（计划数，完成数，放弃数等）
   */
  public async getUserPlanStatistics(userID: string) {
    const planStates = ['NotStarted', 'InProgress', 'Completed', 'Abandoned'];
    const stats: Record<string, number> = {};
    for (const state of planStates) {
      const condition = new cloudDatabase.DatabaseQuery(WorkoutPlan)
        .equalTo('UserID', userID)
        .and()
        .equalTo('PlanState', state);
      const plans = await this.agcDataBase.query(condition);
      stats[state] = plans.length;
    }
    return stats;
  }

  /**
   * 批量更新多个任务状态（例如批量取消）
   */
  public async batchUpdateTasksState(taskIDs: string[], newState: string): Promise<boolean> {
    try {
      for (const id of taskIDs) {
        const condition = new cloudDatabase.DatabaseQuery(PlanTask).equalTo('TaskID', id);
        const tasks = await this.agcDataBase.query(condition);
        if (tasks.length > 0) {
          const task = tasks[0];
          task.State = newState;
          await this.agcDataBase.upsert(task);
        }
      }
      return true;
    } catch (err) {
      console.error('批量更新任务状态失败:', err);
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
