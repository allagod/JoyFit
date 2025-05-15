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

  private constructor() {
  }

  public static getInstance(): PlanTaskService{
    if (!PlanTaskService.instance) {
      PlanTaskService.instance = new PlanTaskService();
    }
    return  PlanTaskService.instance;
  }


  private isToday(date: Date): boolean{
    const now = new Date();
    // 清零时间部分
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfTomorrow = startOfToday + 24 * 60 * 60 * 1000; // 今天午夜 + 1 天
    // 获取目标日期的时间戳
    const targetTime = date.getTime();
    return targetTime >= startOfToday && targetTime < startOfTomorrow;
  }

  public async getTodayTasks(userID:string): Promise<WorkoutPlan[]> {
    let condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID',userID).and(). equalTo('TaskType','workout'); //这个判断条件可能要改
    const Array: PlanTask[]= await this.agcDataBase.query(condition);
    //去除不属于今天的
    const TaskArray: PlanTask[]=[];
    for(let task of Array){
      if(task.ExecutedDate!=undefined)
        if(this.isToday(task.ExecutedDate))
          TaskArray.push(task);
    }
    //hilog.info(1,'今日任务',JSON.stringify(TaskArray));
    let result: WorkoutPlan[]=[];
    for(let task of TaskArray) {
      let condition = new cloudDatabase.DatabaseQuery(WorkoutPlan);
      condition.equalTo('PlanID',task.PlanID);
      let PlanArray: WorkoutPlan[]= await this.agcDataBase.query(condition);
      let res = PlanArray.pop();
      if(res != undefined)
        result.push(res);
    }
    return result;
  }

  //获取计划的动作资源
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

  public async finishTask(taskID:string): Promise<boolean> {
    try{
      let condition = new cloudDatabase.DatabaseQuery(PlanTask);
      condition.equalTo('TaskID', taskID);
      const task : PlanTask[] = await this.agcDataBase.query(condition);
      let res = task.pop();
      if(res!=undefined)
        res.State = "Completed";
      await this.agcDataBase?.upsert(res);
      console.info(`Succeeded in completing a task.`);
      return true;
    }
    catch(err){
      console.info(`Failed in completing a plan: ${JSON.stringify(err)} `);
      return false;
    }
  }

  public async abandonTask(taskID:string): Promise<boolean> {
    try{
      let condition = new cloudDatabase.DatabaseQuery(PlanTask);
      condition.equalTo('TaskID', taskID);
      const task : PlanTask[] = await this.agcDataBase.query(condition);
      let res = task.pop();
      hilog.info(0,'测试',JSON.stringify(res));
      if(res!=undefined)
        res.State = "Abandoned";
      await this.agcDataBase?.upsert(res);
      console.info(`Succeeded in abandoning a task.`);
      return true;
    }
    catch(err){
      console.info(`Failed in abandoning a plan: ${JSON.stringify(err)} `);
      return false;
    }
  }

  public async uploadFeelings(record: WorkoutRecord) {
    try{
      await this.agcDataBase?.upsert(record);
      console.info(`Succeeded in uploading a record.`);
      return true;
    }
    catch(err){
      console.info(`Failed in uploading a record: ${JSON.stringify(err)} `);
      return false;
    }
  }
}
