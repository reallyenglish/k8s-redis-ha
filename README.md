## Redis High Availability deployment with Kubernetes

* Docker images for Redis and Sentinel
* Kubernetes configuration

### Usage

#### Build and push images

If you want to push images closer location to your cluster for such as `asia.gcr.io`:

```console
$ docker build -t asia.gcr.io/your-project-id/redis-ha-server:3.2.8 images/server
$ docker push asia.gcr.io/your-project-id/redis-ha-server:3.2.8

$ docker build -t asia.gcr.io/your-project-id/redis-ha-sentinel:3.2.8 images/sentinel
$ docker push asia.gcr.io/your-project-id/redis-ha-sentinel:3.2.8
```

#### Create kubernetes resources

```console
$ kubectl create namespace ruby-app # <-- replace with your app's namespace
namespace "ruby-app" created
$ kubeclt apply -f kube --namespace=ruby-app
configmap "redis-config" created
configmap "sentinel-config" created
service "redis-ha" created
statefulset "rds" created
```

#### Client access example

[Redis-rb](https://github.com/redis/redis-rb) supports sentinel.

```ruby
SENTINELS = [
  {:host => "rds-0.redis-ha.ruby-app.svc.cluster.local", :port => 26379},
  {:host => "rds-1.redis-ha.ruby-app.svc.cluster.local", :port => 26379},
  {:host => "rds-2.redis-ha.ruby-app.svc.cluster.local", :port => 26379},
]

redis = Redis.new(
  host: 'ha-master' # the gem uses 'host' param as master name
  sentinels: SENTINELS, role: :master,
  timeout: 10, connect_timeout: 15
)
```

### Reference

* [Redis Replication](https://redis.io/topics/replication)
* [Redis Sentinel Documentation](https://redis.io/topics/sentinel)
* [Redis-rb sentinel support](https://github.com/redis/redis-rb#sentinel-support)
