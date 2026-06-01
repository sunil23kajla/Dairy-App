const fs = require('fs');
const path = require('path');
const dbPath = path.join(__dirname, 'database.json');

let memoryDB = {};
try {
  if (fs.existsSync(dbPath)) {
    const data = fs.readFileSync(dbPath, 'utf8');
    memoryDB = JSON.parse(data);
  }
} catch (e) {
  console.log('No existing database.json or failed to load');
}

function saveDB() {
  const dataToSave = {};
  for (const key in memoryDB) {
    dataToSave[key] = memoryDB[key].map(item => {
      // Convert Maps (like workers) to plain objects before saving to JSON
      const serialized = { ...item };
      if (serialized.workers instanceof Map) {
        serialized.workers = Object.fromEntries(serialized.workers);
      }
      return serialized;
    });
  }
  fs.writeFileSync(dbPath, JSON.stringify(dataToSave, null, 2), 'utf8');
}

class MockQuery {
  constructor(result) {
    this.result = result;
  }
  then(res, rej) { return Promise.resolve(this.result).then(res, rej); }
  catch(rej) { return Promise.resolve(this.result).catch(rej); }
}

class MockModel {
  constructor(data) {
    Object.assign(this, data);
    if (this.constructor.modelName === 'Dairy') {
      if (!this.workers || !(this.workers instanceof Map)) {
        this.workers = new Map(Object.entries(this.workers || {}));
      }
    }
    this.save = async () => {
      if (!memoryDB[this.constructor.modelName]) memoryDB[this.constructor.modelName] = [];
      const idx = memoryDB[this.constructor.modelName].findIndex(i => i.code === this.code || i.id === this.id);
      if (idx !== -1) {
        memoryDB[this.constructor.modelName][idx] = this;
      } else {
        memoryDB[this.constructor.modelName].push(this);
      }
      saveDB();
      return this;
    };
  }

  static get dataList() {
    if (!memoryDB[this.modelName]) memoryDB[this.modelName] = [];
    memoryDB[this.modelName] = memoryDB[this.modelName].map(item => {
      if (!(item instanceof MockModel)) {
        return new this(item);
      }
      return item;
    });
    return memoryDB[this.modelName];
  }

  static findOne(query) {
    if (query['$or']) {
      for (const item of this.dataList) {
        for (const cond of query['$or']) {
          let match = true;
          for (const key in cond) {
            if (item[key] !== cond[key]) match = false;
          }
          if (match) return new MockQuery(item);
        }
      }
      return new MockQuery(null);
    }
    const item = this.dataList.find(i => {
      for (const k in query) {
        if (query[k] && query[k].source && typeof query[k] === 'object') {
          // regex
          if (!new RegExp(query[k].source, query[k].flags).test(i[k])) return false;
        } else {
          if (i[k] !== query[k]) return false;
        }
      }
      return true;
    });
    return new MockQuery(item || null);
  }

  static find(query) {
    return new MockQuery(this.dataList);
  }

  static findOneAndUpdate(query, update, options) {
    let item = this.dataList.find(i => {
      for (const k in query) {
        if (i[k] !== query[k]) return false;
      }
      return true;
    });
    if (item) {
      if (update.$set) Object.assign(item, update.$set);
      else Object.assign(item, update);
      saveDB();
      return new MockQuery(item);
    } else if (options && options.upsert) {
      item = { ...query };
      if (update.$set) Object.assign(item, update.$set);
      else Object.assign(item, update);
      this.dataList.push(item);
      saveDB();
      return new MockQuery(item);
    }
    return new MockQuery(null);
  }

  static findOneAndDelete(query) {
    const idx = this.dataList.findIndex(i => {
      for (const k in query) {
        if (i[k] !== query[k]) return false;
      }
      return true;
    });
    if (idx !== -1) {
      const item = this.dataList.splice(idx, 1)[0];
      saveDB();
      return new MockQuery(item);
    }
    return new MockQuery(null);
  }
  
  static insertMany(items) {
    for (const item of items) {
      this.dataList.push(item);
    }
    saveDB();
    return new MockQuery(items);
  }

  static async updateMany(query, update) {
    for (const item of this.dataList) {
       Object.assign(item, update.$set);
    }
    saveDB();
    return { modifiedCount: this.dataList.length };
  }
}

module.exports = {
  connect: () => Promise.resolve(),
  Schema: class { 
    constructor(schema) { this.schema = schema; } 
    index() {} 
  },
  model: (name, schema) => {
    const m = class extends MockModel {};
    m.modelName = name;
    return m;
  }
};
