---
title: "free人事労務のAPI使ってみた"
date: 2023-10-19T07:43:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "結局運用まで至らないが"
linkedinurl: ""
weight: 7
tags:
  - freee人事労務
  - API
  - OAuth
  - REST API
  - 勤怠管理
  - プログラミング
  - TypeScript
  - 連携
---

勤怠管理にはfree人事労務を使っている。残業する場合、残業申請と勤務時間を両方別画面で入力するのは大変手間である。
APIを使って一括で入力できないかと模索しましたが、結局は実現できませんでした。
理由は、残業申請登録APIにリクエストしたら`役職、部門を利用する申請はWebから申請してください。`とResponseが返ってきました。（は！？はあああ！？
しかし、頑張ってRest Clientで書いたので、メモとして残しておきます。

```bash
# OAuth のRest 必ず最初にやる
@oauth_base_url = https://accounts.secure.freee.co.jp

## 1. 認可コードを取得

@application_client_id = 
@application_client_secret = 
@authorization_code = 

###　2. アクセストークンを取得する
# @name public_api_token
POST {{oauth_base_url}}/public_api/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&client_id={{application_client_id}}&client_secret={{application_client_secret}}&code={{authorization_code}}&redirect_uri=urn:ietf:wg:oauth:2.0:oob

### set access and refresh token 

@access_token = {{public_api_token.response.body.$.access_token}}
@refresh_token = {{public_api_token.response.body.$.refresh_token}}

### リフレッシュトークンでアクセストークンを再取得

## @name public_api_refresh_token
#POST {{oauth_base_url}}/public_api/token
#Content-Type: application/x-www-form-urlencoded

#grant_type=refresh_token&client_id={{application_client_id}}&client_secret={{application_client_secret}}&refresh_token={{refresh_token}}

### update access and refresh token 

# @access_token = {{public_api_refresh_token.response.body.$.access_token}}
# @refresh_token = {{public_api_refresh_token.response.body.$.refresh_token}}

# Free 人事労務API
@api_base_url = https://api.freee.co.jp/hr

### me
# @name hr_me_request
GET {{api_base_url}}/api/v1/users/me
accept: application/json
Authorization: Bearer {{access_token}}

### set company id& employee id
@company_id = {{hr_me_request.response.body.$.companies[0].id}}
@employee_id = {{hr_me_request.response.body.$.companies[0].employee_id}}
@applicant_id = {{hr_me_request.response.body.$.id}}

### time clocks

GET {{api_base_url}}/api/v1/employees/{{employee_id}}/time_clocks?company_id={{company_id}}
accept: application/json
Authorization: Bearer {{access_token}}


### get work record

GET {{api_base_url}}/api/v1/employees/{{employee_id}}/work_records/2023-10-16?company_id={{company_id}}
accept: application/json
Authorization: Bearer {{access_token}}


### 勤務時間登録
@work_date_YYYY-MM-DD = 2023-10-17
PUT {{api_base_url}}/api/v1/employees/{{employee_id}}/work_records/{{work_date_YYYY-MM-DD}}
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

{
    "company_id": "{{company_id}}",
    "break_records": [
        {
        "clock_in_at": "{{work_date_YYYY-MM-DD}} 12:00:00",
        "clock_out_at": "{{work_date_YYYY-MM-DD}} 13:00:00"
        }
    ],
    "clock_in_at": "{{work_date_YYYY-MM-DD}} 09:30:00",
    "clock_out_at": "{{work_date_YYYY-MM-DD}} 19:00:00"
}

### 残業申請一覧
GET {{api_base_url}}/api/v1/approval_requests/overtime_works?company_id={{company_id}}
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

### 残業申請詳細
GET {{api_base_url}}/api/v1/approval_requests/overtime_works/4635784?company_id={{company_id}}
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

### 申請経路一覧

#### usageはAttendanceWorkflow:勤怠申請、PersonalDataWorkflow:身上変更申請または指定なし
GET {{api_base_url}}/api/v1/approval_flow_routes?company_id={{company_id}}&usage=AttendanceWorkflow
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

### 申請経路詳細

GET {{api_base_url}}/api/v1/approval_flow_routes/641542?company_id={{company_id}}
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

### 残業申請登録
#### 部門を利用しているためWebからの申請しかできない
@target_date_YYYY-MM-DD = 2023-10-17
@overtime_works_end_at_hh:mm = 19:00
@overtime_works_reason = システム部打ち合わせ

POST {{api_base_url}}/api/v1/approval_requests/overtime_works
accept: application/json
content-type: application/json
Authorization: Bearer {{access_token}}

{
  "company_id": "{{company_id}}",
  "target_date": "{{target_date_YYYY-MM-DD}}",
  "start_at": "18:30",
  "end_at": "{{overtime_works_end_at_hh:mm}}",
  "comment": "{{overtime_works_reason}}",
  "approval_flow_route_id": 641542
}
```

参考

- [人事労務APIリファレンス](https://developer.freee.co.jp/reference/hr/reference)
