export class UserInfo {
  private _nickname: string;
  private _avatar: string;
  private _age: number;
  private _sex: string;
  private _city: string;

  private constructor(
    nickname: string,
    avatar: string,
    age: number,
    sex: string,
    city: string
  ) {
    this._nickname = nickname;
    this._avatar = avatar;
    this._age = age;
    this._sex = sex;
    this._city = city;
  }

  // 工厂方法
  public static create(data: {
    nickname: string;
    avatar: string;
    age: number;
    sex: string;
    city: string;
  }): UserInfo {
    return new UserInfo(
      data.nickname,
      data.avatar,
      data.age,
      data.sex,
      data.city
    );
  }

  public get nickname(): string {
    return this._nickname;
  }

  public set nickname(value: string) {
    if (!value) throw new Error("Nickname cannot be empty");
    this._nickname = value;
  }

  public get avatar(): string {
    return this._avatar;
  }

  public set avatar(value: string) {
    if (!value.startsWith("http") && !value.endsWith(".png") && !value.endsWith(".jpg")) {
      console.warn("Avatar URL may be invalid");
    }
    this._avatar = value;
  }

  public get age(): number {
    return this._age;
  }

  public set age(value: number) {
    if (value < 0 || value > 120) {
      throw new Error("Age must be between 0 and 120");
    }
    this._age = value;
  }

  public get sex(): string {
    return this._sex;
  }

  public set sex(value: string) {
    if (!["male", "female", "other"].includes(value.toLowerCase())) {
      console.warn("Sex value is not standard: expected 'male', 'female', or 'other'");
    }
    this._sex = value;
  }

  public get city(): string {
    return this._city;
  }

  public set city(value: string) {
    this._city = value.trim();
  }

  // 用于数据库或前端展示
  public toJSON() {
    return {
      nickname: this._nickname,
      avatar: this._avatar,
      age: this._age,
      sex: this._sex,
      city: this._city,
    };
  }
}
