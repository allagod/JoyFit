import { cloudDatabase } from '@kit.CloudFoundationKit';

// WorkoutRecord 类，继承 cloudDatabase.DatabaseObject
class WorkoutRecord extends cloudDatabase.DatabaseObject {
  // 返回类名，供 Cloud DB 使用
  public override naturalbase_ClassName(): string {
    return 'WorkoutRecord';
  }

  public RecordID?: number;        // Integer 类型，编号
  public Image?: string;           // String 类型，图片路径
  public Feeling?: string;         // Text 类型，用户感受
  public RecordDate?: Date;        // Date 类型，记录时间
  public Calories?: number;        // Double 类型，消耗卡路里
  public PlanID?: number;          // Integer 类型，计划 ID
}

export { WorkoutRecord };
