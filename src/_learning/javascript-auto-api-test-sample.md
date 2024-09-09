---
title: "javascriptを使って自動テスト回収前後でResponseに差異がないことを確認する"
date: 2024-03-6T14:31:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
---


SQLのクエリコスト低減をやって、既存のAPIへの影響がないのか
確認するため自動テストを作成しました。

テストは至って簡単
新旧のAPIを立ち上げた状態で、それぞれ同じEndポイントへリクエストし、
Bodyの内容に差異がないかを確認します。
差異が発生した場合は、Logを出力するようになっています。
また調査した内容と、propertyがすべてNullでは意味ないので、
propertyに値がある状態だったのかをlogに出力して、後で確認できるようにしました。

```javascript
const axios = require('axios');
const mysql = require('mysql');
const util = require('util');
const fs = require('fs');
const path = require('path');
const { StopWatch } = require('stopwatch-node');

const appendFile = util.promisify(fs.appendFile);

let pool = mysql.createPool({
    host: 'localhost',
    user: 'local',
    password: 'password',
    database: 'contacts',
    connectionLimit: 1,
});
pool.query = util.promisify(pool.query);

const apiServerDev746BaseURI = 'http://localhost:3000';
const apiServerOrignBaseURI = 'http://localhost:3001';
const endPoint = 'api/call/summary/all';

const httpRequestHeaders = { 'Content-Type': 'application/json', 'x-access-token': '{token}' };

const executeQuery = async (query, params = []) => pool.query(query, params);
async function getTestUsers() {
    const query = `
        SELECT users.hospitalId,users.id
        FROM users 
        INNER JOIN calls ON users.id = calls.ownerId
        WHERE type = 1
        GROUP BY users.hospitalId,users.id
        ORDER BY users.hospitalId,users.id;
    `;
    return executeQuery(query);
}

async function runExperiments(userId, hospitalId, logFunction) {
    let offset = 0;
    let successed = false;
    while (true) {
        const urls = [apiServerDev746BaseURI, apiServerOrignBaseURI].map(baseURI => `${baseURI}/${endPoint}/${offset}/${hospitalId}/${userId}`);
        const [responseDev746, responseOrign] = await Promise.all(urls.map(url => axios.get(url, { headers: httpRequestHeaders })));
        const results = { hospitalId, userId, dev746Res: JSON.stringify(responseDev746.data), orignRes: JSON.stringify(responseOrign.data) };
        if (results.dev746Res === results.orignRes) {
            const calls = responseDev746.data.data?.calls;

            await logFunction({ isCompare: true, results, urls, responseDev746, responseOrign });
            if (calls && calls.length > 0) {
                offset++;
                continue;
            }
            successed = true;
            break;
        } else {
            await logFunction({ isCompare: false, results, urls, responseDev746, responseOrign });
            successed = false;
            break;
        }
    }

    return successed;
}

function checkProperties(obj, path = '') {
    let result = [];

    for (let key in obj) {
        if (obj.hasOwnProperty(key)) {
            const fullPath = path ? `${path}.${key}` : key;
            const value = obj[key];

            const hasValue = value !== null && value !== undefined && value !== '';

            result.push({ propertyName: fullPath, hasValue });

            if (typeof value === 'object' && value !== null) {
                result = result.concat(checkProperties(value, fullPath));
            }
        }
    }

    return result;
}

(async () => {
    const sw = new StopWatch('Test');
    let users = [];
    const dryRun = false;

    sw.start("DB");
    console.log('Connecting to MySQL database...');
    try {
        if (dryRun) {
            users = [{ id: 4242, hospitalId: 21 }]
        } else {
            users = await getTestUsers();
        }
    } catch (error) {
        console.error('Error: ', error);
    } finally {
        pool.end();
        sw.stop("DB");
    }

    const now = Date.now();
    const missmatchLogPath = path.join(__dirname, `dev-746_miss_match_log_${now}.txt`);
    const searchLogPath = path.join(__dirname, `dev-746_search_log_${now}.txt`);
    const propertyLogPath = path.join(__dirname, `dev-746_property_log_${now}.txt`);

    const logFunc = async ({ isCompare, results, urls, responseDev746, responseOrign }) => {
        results.urls = urls;

        const calls = responseOrign.data.data?.calls;
        if(calls && calls.length > 0)
        {
            for(const call of calls)
            {
                const propertiesCheckResult = checkProperties(call);
                appendFile(propertyLogPath, call.id +':' + JSON.stringify(propertiesCheckResult) + '\n');
            }
        }

        await appendFile(searchLogPath, JSON.stringify({ isCompare, 
            urls, 
            dev746_data_count: responseDev746.data.data?.calls?.length , 
            orign_data_count: responseOrign.data.data?.calls?.length 
        }) + '\n');
        if (!isCompare) {
            await appendFile(missmatchLogPath, JSON.stringify(results, null, 2) + '\n');
        }
    }

    sw.start("API");
    for (const user of users) {
        await runExperiments(user.id, user.hospitalId, logFunc);
    }
    sw.stop("API");

    sw.prettyPrint();
})();
```
