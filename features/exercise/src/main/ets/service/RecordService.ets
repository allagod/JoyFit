import { cloudDatabase } from "@kit.CloudFoundationKit";
import { PlanTask } from "../bean/PlanTask";
import { RunningRecord } from "../bean/RunningRecord";
import { WorkoutRecord } from "../bean/WorkoutRecord";


export class RecordService {

  private static instance: RecordService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {
  }

  public static getInstance(): RecordService{
    if (!RecordService.instance) {
      RecordService.instance = new RecordService();
    }
    return  RecordService.instance;
  }

  public async getFeelingsByPlan(userID: string, planID: string,type:string) {
    if(type == "workout"){
      let condition = new cloudDatabase.DatabaseQuery(WorkoutRecord);
      condition.equalTo('UserID',userID).and().equalTo('PlanID',planID);
      const planArray: WorkoutRecord[]= await this.agcDataBase.query(condition);
      return planArray;
    }
    else if (type =='running'){
      let condition = new cloudDatabase.DatabaseQuery(RunningRecord);
      condition.equalTo('UserID',userID).and().equalTo('PlanID',planID);
      const planArray: RunningRecord[]= await this.agcDataBase.query(condition);
      return planArray;
    }
    return [];
  }

  public async getRecords(userID: string, planID: string,type:string) {
    let condition = new cloudDatabase.DatabaseQuery(PlanTask);
    if(type == 'workout')
      condition.equalTo('UserID',userID).and().equalTo('PlanID',planID).and().equalTo('TaskType','workout');
    else
      condition.equalTo('UserID',userID).and().equalTo('PlanID',planID).and().equalTo('TaskType','running');
    const planArray: PlanTask[]= await this.agcDataBase.query(condition);
    return planArray;
  }
}
