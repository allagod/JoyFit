import {ExercisePlanService} from '../service/ExercisePlanService'
import {RunningPlan} from'../bean/RunningPlan'
import { cloudDatabase } from '@kit.CloudFoundationKit';
import {runningPlan} from '../model/runningPlan'
import { PlanTask } from '../bean/PlanTask';
import {UUIDGenerator} from 'utils'
import { RunningRecord } from '../bean/RunningRecord';
import { runningPlanBuilder } from '../model/runningPlanBuilder';
import { WorkoutPlan } from '../bean/WorkoutPlan';

export class RunningPlanService extends ExercisePlanService{

  private static instance: RunningPlanService | null = null;

  private constructor() {
    super();
  }

  public static getInstance(): RunningPlanService{
    if (!RunningPlanService.instance) {
      RunningPlanService.instance = new  RunningPlanService();
    }
    return  RunningPlanService.instance;
  }

  // 创建 RunningPlan 的构建器
  public createPlanBuilder(): runningPlanBuilder {
    return new runningPlanBuilder();
  }

  // 获取用户今天的待执行跑步任务对应的计划信息
  public async getTodayTasks(userID:string): Promise<RunningPlan[]> {
    let currentTime = new Date();
    let condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID',userID).and().equalTo('ExecutedDate',currentTime).and().equalTo('TaskType','running').and().equalTo('State','Pending');
    const TaskArray: PlanTask[]= await this.agcDataBase.query(condition);
    let result: RunningPlan[]=[];
    for(let task of TaskArray) {
      let condition = new cloudDatabase.DatabaseQuery(RunningPlan);
      condition.equalTo('PlanID',task.PlanID);
      let PlanArray: RunningPlan[]= await this.agcDataBase.query(condition);
      let res = PlanArray.pop();
      if(res != undefined)
        result.push(res);
    }
    return result;
  }

  // 将 runningPlan 对象转换为 RunningPlan 数据表实体
  private runningPlanToBean(plan: runningPlan,id:string) {
    let planContent = new RunningPlan();
    planContent.PlanID = plan.PlanID;
    planContent.UserID = id;
    planContent.PlanName = plan.PlanName;
    planContent.CoverPicture = plan.CoverPicture;
    planContent.PlanState = plan.PlanState;
    planContent.EndDate = plan.EndDate;
    planContent.DayOfWeek = plan.DayOfWeek;
    planContent.StartDate = plan.StartDate;
    planContent.GoalOfTotalTime = plan.GoalOfTotalTime;
    planContent.GoalOfTotalMiles = plan.GoalOfTotalMiles;
    planContent.GoalOfSpeed = plan.GoalOfSpeed;
    return planContent;
  }

  // 删除计划（目前未实现）
  public async deletePlan(planID: string) {
    // 方法尚未实现
  }

  // 上传新的跑步计划及其对应的任务列表
  public async uploadPlan(plan: runningPlan, userID: string): Promise<boolean> {
    const planContent = this.runningPlanToBean(plan, userID);
    let targetDates = this.getExecutionDates(plan.StartDate, plan.EndDate, plan.DayOfWeek);
    let taskArr: PlanTask[] = [];
    for(let date of targetDates){
      if(plan.PlanID != undefined)
        taskArr.push(this.taskToBean(plan.PlanID, userID, date))
    }
    try {
      await this.agcDataBase?.upsert(planContent);
      await this.agcDataBase?.upsert(planContent); // 注意可能存在重复插入
      return true;
    } catch (err) {
      return false;
    }
  }

  // 更新已有跑步计划
  public async updatePlan(plan: runningPlan, userID: string): Promise<boolean> {
    const planContent = this.runningPlanToBean(plan, userID);
    try {
      await this.agcDataBase?.upsert(planContent);
      return true;
    } catch (err) {
      return false;
    }
  }

  // 获取未开始的跑步计划
  public async getNotStartedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(RunningPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','NotStarted');
    const planArray: RunningPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  // 获取已完成的跑步计划
  public async getCompletedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(RunningPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','Completed');
    const planArray: RunningPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  // 获取正在进行中的跑步计划
  public async getInProgressPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(RunningPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','InProgress');
    const planArray: RunningPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  // 获取已放弃的跑步计划
  public async getAbandonedPlan(userID:string) {
    let condition = new cloudDatabase.DatabaseQuery(RunningPlan);
    condition.equalTo('UserID',userID).and().equalTo('PlanState','Abandoned');
    const planArray: RunningPlan[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  // 将正在进行的计划标记为放弃
  public async abandonInProgressPlan(targetPlan:RunningPlan){
    try{
      targetPlan.PlanState = "Abandoned";
      await this.agcDataBase?.upsert(targetPlan);
      console.info(`Succeeded in abandoning a plan.`);
      return true;
    }
    catch(err){
      console.info(`Failed in abandoning a plan: ${JSON.stringify(err)} `);
      return false;
    }
  }

  // 获取指定计划的所有用户感受记录
  public async getFeelingsByPlan(userID: string, planID: string) {
    let condition = new cloudDatabase.DatabaseQuery(RunningRecord);
    condition.equalTo('UserID',userID).and().equalTo('PlanID',planID);
    const planArray: RunningRecord[]= await this.agcDataBase.query(condition);
    return planArray;
  }

  // 获取与计划关联的所有 PlanTask 记录
  public async getRecords(userID: string, planID: string) {
    let condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID',userID).and().equalTo('PlanID',planID).and().equalTo('TaskType','running');
    const planArray: PlanTask[]= await this.agcDataBase.query(condition);
    return planArray;
  }

}
