COUNTER = 1;

var Promise = function(affair){
    this.state = 'pending';
    this.affair = affair || function(obj) { return obj; };
    this.allAffairs = [];
    this._id = COUNTER++;
    console.log("in Promise constructor, id: " + this._id);
};
Promise.prototype = {
    resolve: function(obj){
        console.log("currently in Promise : " + this._id + " method resolve.");
        if (this.state != 'pending') throw '已完成，不能再次resolve';
        this.state = 'resloved';
        this.result = this.affair(obj); // 执行ok

        for (var i=0, len=this.allAffairs.length; i<len; ++i){
            // 依次调用该任务的后续任务
            var affair = this.allAffairs[i];
            this._fire(affair.promise, affair.affair);
        }
        return this;
    },
    _fire: function(nextPromise, nextAffair){
        console.log("currently in Promise : " + this._id + " method _fire, nextPromise: " + nextPromise._id);
        var nextResult = nextAffair(this.result); // 调用nextAffair

        if (nextResult instanceof Promise){
            console.log("nextAffair is executed, returns another Promise, id: " + nextResult._id);
            // 异步的情况，返回值是一个Promise，则当其resolve的时候，nextPromise才会被resolve
            nextResult.then(function(obj){
                nextPromise.resolve(obj);
            });
        }else{
            // 同步的情况，返回值是普通结果，立即将nextPromise给resolve掉
            nextPromise.resolve(nextResult);
        }
        return nextPromise;
    },
    _push: function(nextPromise, nextAffair){
        console.log("currently in Promise : " + this._id + " method _push, nextPromise: " + nextPromise._id);
        this.allAffairs.push({
            promise: nextPromise,
            affair: nextAffair
        });
        return nextPromise;
    },
    then: function(nextAffair){
        console.log("currently in Promise : " + this._id + " method then, nextAffair: " + nextAffair);
        var promise = new Promise();
        if (this.state == 'resloved'){
            // 如果当前状态是已完成，则nextAffair会被立即调用
            return this._fire(promise, nextAffair);
        }else{
            // 否则将会被加入队列中
            return this._push(promise, nextAffair);
        }
    }
};

