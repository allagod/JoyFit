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
