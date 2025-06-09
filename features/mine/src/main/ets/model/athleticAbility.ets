export class AthleticAbility {
  constructor(
    private _runningDistance: number = 0,
    private _pushUpNums: number = 0,
    private _squatNums: number = 0,
    private _crunchNums: number = 0
  ) {}

  // 创建工厂方法
  public static create(data: {
    runningDistance?: number;
    pushUpNums?: number;
    squatNums?: number;
    crunchNums?: number;
  }): AthleticAbility {
    return new AthleticAbility(
      data.runningDistance ?? 0,
      data.pushUpNums ?? 0,
      data.squatNums ?? 0,
      data.crunchNums ?? 0
    );
  }

  // 跑步距离
  public get runningDistance(): number {
    return this._runningDistance;
  }

  public set runningDistance(value: number) {
    this._runningDistance = this.validate(value, 'RunningDistance');
  }

  // 俯卧撑数量
  public get pushUpNums(): number {
    return this._pushUpNums;
  }

  public set pushUpNums(value: number) {
    this._pushUpNums = this.validate(value, 'PushUpNums');
  }

  // 深蹲数量
  public get squatNums(): number {
    return this._squatNums;
  }

  public set squatNums(value: number) {
    this._squatNums = this.validate(value, 'SquatNums');
  }

  // 仰卧起坐数量
  public get crunchNums(): number {
    return this._crunchNums;
  }

  public set crunchNums(value: number) {
    this._crunchNums = this.validate(value, 'CrunchNums');
  }

  // 校验函数
  private validate(value: number, field: string): number {
    if (value < 0 || !Number.isFinite(value)) {
      console.warn(`[AthleticAbility] Invalid value for ${field}:`, value);
      return 0;
    }
    return value;
  }

  // 序列化成 JSON
  public toJSON() {
    return {
      runningDistance: this._runningDistance,
      pushUpNums: this._pushUpNums,
      squatNums: this._squatNums,
      crunchNums: this._crunchNums
    };
  }
}
