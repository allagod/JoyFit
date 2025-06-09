export class Achievement {
  constructor(
    private _achievementID: string,
    private _medalName: string,
    private _achieveTime: Date,
    private _medalImage: string,
    private _description: string
  ) {}

  // 工厂方法，支持对象式传参
  public static create(data: {
    achievementID: string;
    medalName: string;
    achieveTime: Date;
    medalImage: string;
    description: string;
  }): Achievement {
    return new Achievement(
      data.achievementID,
      data.medalName,
      data.achieveTime,
      data.medalImage,
      data.description
    );
  }

  // 成就 ID
  public get achievementID(): string {
    return this._achievementID;
  }

  public set achievementID(value: string) {
    this._achievementID = value;
  }

  // 勋章名称
  public get medalName(): string {
    return this._medalName;
  }

  public set medalName(value: string) {
    this._medalName = value;
  }

  // 成就时间
  public get achieveTime(): Date {
    return this._achieveTime;
  }

  public set achieveTime(value: Date) {
    this._achieveTime = value;
  }

  // 勋章图片路径
  public get medalImage(): string {
    return this._medalImage;
  }

  public set medalImage(value: string) {
    this._medalImage = value;
  }

  // 成就描述
  public get description(): string {
    return this._description;
  }

  public set description(value: string) {
    this._description = value;
  }

  // 将对象序列化为 JSON（用于网络传输或日志）
  public toJSON() {
    return {
      achievementID: this._achievementID,
      medalName: this._medalName,
      achieveTime: this._achieveTime.toISOString(),
      medalImage: this._medalImage,
      description: this._description
    };
  }
}
