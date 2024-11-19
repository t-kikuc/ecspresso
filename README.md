# ecspresso

ecspresso is a deployment tool for Amazon ECS.

(pronounced the same as "espresso" :coffee:)

## Documents

- [Differences between v1 and v2](docs/v1-v2.md).
- [ecspresso Advent Calendar 2020](https://adventar.org/calendars/5916) (Japanese)
- [ecspresso handbook](https://zenn.dev/fujiwara/books/ecspresso-handbook-v2) (Japanese)
- [Command Reference](https://zenn.dev/fujiwara/books/ecspresso-handbook-v2/viewer/reference) (Japanese)

## Install

### Homebrew (macOS and Linux)

```console
$ brew install kayac/tap/ecspresso
```

### asdf (macOS and Linux)

```console
$ asdf plugin add ecspresso
# or
$ asdf plugin add ecspresso https://github.com/kayac/asdf-ecspresso.git

$ asdf install ecspresso 2.3.0
$ asdf global ecspresso 2.3.0
```

### aqua (macOS and Linux)

[aqua](https://aquaproj.github.io/) is a CLI version manager.

```console
$ aqua g -i kayac/ecspresso
```

### Binary packages

[Releases](https://github.com/kayac/ecspresso/releases)

### CircleCI Orbs

https://circleci.com/orbs/registry/orb/fujiwara/ecspresso

```yaml
version: 2.1
orbs:
  ecspresso: fujiwara/ecspresso@2.0.4
jobs:
  install:
    steps:
      - checkout
      - ecspresso/install:
          version: v2.3.0 # or latest
          # version-file: .ecspresso-version
          os: linux # or windows or darwin
          arch: amd64 # or arm64
      - run:
          command: |
            ecspresso version
```

`version: latest` installs different versions of ecspresso for each Orb version.
- fujiwara/ecspresso@0.0.15
  - The latest release version (v2 and later)
- fujiwara/ecspresso@1.0.0
  - The latest version of v1.x
- fujiwara/ecspresso@2.0.3
  - The latest version of v2.x

Note: `version: latest` is not recommended as it may cause unexpected behavior when a new version of ecspresso is released.

Orb `fujiwara/ecspresso@2.0.2` supports `version-file: path/to/file`, which installs the ecspresso version specified in the file. This version number does not have a `v` prefix, For example, `2.0.0`.

### GitHub Actions

Action kayac/ecspresso@v2 installs an ecspresso binary for Linux(x86_64) into /usr/local/bin. This action runs install only.

```yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: kayac/ecspresso@v2
        with:
          version: v2.3.0 # or latest
          # version-file: .ecspresso-version
      - run: |
          ecspresso deploy --config ecspresso.yml
```

To use the latest version of ecspresso, pass the parameter "latest".

```yaml
      - uses: kayac/ecspresso@v2
        with:
          version: latest
```

`version: latest` installs different versions of ecspresso for each Action version.
- kayac/ecspresso@v1
  - The latest version of v1.x
- kayac/ecspresso@v2
  - The latest version of v2.x

Note: `version: latest` is not recommended as it may cause unexpected behavior when a new version of ecspresso is released.

Action `kayac/ecspresso@v2` supports `version-file: path/to/file`, which installs the ecspresso version specified in the file. This version number does not have a `v` prefix, For example `2.3.0`.

## Usage

```
Usage: ecspresso <command>

Flags:
  -h, --help                      Show context-sensitive help.
      --envfile=ENVFILE,...       environment files ($ECSPRESSO_ENVFILE)
      --debug                     enable debug log ($ECSPRESSO_DEBUG)
      --ext-str=KEY=VALUE;...     external string values for Jsonnet ($ECSPRESSO_EXT_STR)
      --ext-code=KEY=VALUE;...    external code values for Jsonnet ($ECSPRESSO_EXT_CODE)
      --config="ecspresso.yml"    config file ($ECSPRESSO_CONFIG)
      --assume-role-arn=""        the ARN of the role to assume ($ECSPRESSO_ASSUME_ROLE_ARN)
      --timeout=TIMEOUT           timeout. Override in a configuration file ($ECSPRESSO_TIMEOUT).
      --filter-command=STRING     filter command ($ECSPRESSO_FILTER_COMMAND)
      --[no-]color                enable colorized output ($ECSPRESSO_COLOR)

Commands:
  appspec
    output AppSpec YAML for CodeDeploy to STDOUT

  delete
    delete service

  deploy
    deploy service

  deregister
    deregister task definition

  diff
    show diff between task definition, service definition with current running
    service and task definition

  exec
    execute command on task

  init --service=SERVICE
    create configuration files from existing ECS service

  refresh
    refresh service. equivalent to deploy --skip-task-definition
    --force-new-deployment --no-update-service

  register
    register task definition

  render <targets>
    render config, service definition or task definition file to STDOUT

  revisions
    show revisions of task definitions

  rollback
    rollback service

  run
    run task

  scale
    scale service. equivalent to deploy --skip-task-definition
    --no-update-service

  status
    show status of service

  tasks
    list tasks that are in a service or having the same family

  verify
    verify resources in configurations

  wait
    wait until service stable

  version
    show version
```

For more options for sub-commands, See `ecspresso sub-command --help`.

## Quick Start

ecspresso allows you to easily manage your existing/running ECS services by code.

Try `ecspresso init` for your ECS service with option `--region`, `--cluster` and `--service`.

```console
$ ecspresso init --region ap-northeast-1 --cluster default --service myservice --config ecspresso.yml
2019/10/12 01:31:48 myservice/default save service definition to ecs-service-def.json
2019/10/12 01:31:48 myservice/default save task definition to ecs-task-def.json
2019/10/12 01:31:48 myservice/default save config to ecspresso.yml
```

Review the generated files: `ecspresso.yml`, `ecs-service-def.json`, and `ecs-task-def.json`.

Now you can deploy the service using ecspresso!

```console
$ ecspresso deploy --config ecspresso.yml
```

### Next step

ecspresso can read service and task definition files as a template. A typical use case is to replace the image's tag in the task definition file.

Modify ecs-task-def.json as below.

```diff
-  "image": "nginx:latest",
+  "image": "nginx:{{ must_env `IMAGE_TAG` }}",
```

Then, deploy the service with environment variable `IMAGE_TAG`.

```console
$ IMAGE_TAG=stable ecspresso deploy --config ecspresso.yml
```

For more information, refer to the [Configuration file](#configuration-file) and [Template syntax](#template-syntax) sections.

## Configuration file

A configuration file for ecspresso (YAML, JSON, or Jsonnet format).

```yaml
region: ap-northeast-1 # or AWS_REGION environment variable
cluster: default
service: myservice
task_definition: taskdef.json
timeout: 5m # default 10m
ignore:
  tags:
    - ecspresso:ignore # ignore tags of service and task definition
```

`ecspresso deploy` works as below.

- Register a new task definition from `task-definition` file (JSON or Jsonnet).
  - Replace ```{{ env `FOO` `bar` }}``` syntax in the JSON file with environment variable "FOO".
    - If "FOO" is not defined, replaced by "bar"
  - Replace ```{{ must_env `FOO` }}``` syntax in the JSON file wth environment variable "FOO".
    - If "FOO" is not defined, abort immediately.
- Update service tasks by the `service_definition` file (JSON or Jsonnet).
- Wait for the service to be stable.

Configuration files and task/service definition files are read by [go-config](https://github.com/kayac/go-config) which provides template functions `env`, `must_env` and `json_escape`.

## Template syntax

ecspresso uses the [text/template standard package in Go](https://pkg.go.dev/text/template) to render template files, and parses them as YAML or JSON.

When using Jsonnet, ecspresso first renders the Jsonnet files and then parses them as text/template. As a result, template functions can only render string values using "{{ ... }}", since the template function syntax {{ }} conflicts with Jsonnet syntax. To render non-string values, consider using [Jsonnet functions](#jsonnet-functions) instead.

By default, ecspresso provides the following as template functions.

### `env`

```
"{{ env `NAME` `default value` }}"
```

This replaces the placeholder with the value of the environment variable NAME. If not set, it defaults to "default value".

### `must_env`

```
"{{ must_env `NAME` }}"
```

This replaces the placeholder with the value of environment variable NAME. If not set, ecspresso will panic and stop forcefully.

Defining critical values with `must_env` helps prevent unintended deployments by ensuring these values are set before execution.

### `json_escape`

```
"{{ must_env `JSON_VALUE` | json_escape }}"
```

This escapes values as JSON strings, which is useful for embedding values as strings that require escaping, such as quotes.

### Plugin provided template functions

ecspresso also adds some template functions via plugins. See the [Plugins](#plugins) section.

## Example of deployment

### Rolling deployment

```console
$ ecspresso deploy --config ecspresso.yml
2017/11/09 23:20:13 myService/default Starting deploy
Service: myService
Cluster: default
TaskDefinition: myService:3
Deployments:
    PRIMARY myService:3 desired:1 pending:0 running:1
Events:
2017/11/09 23:20:13 myService/default Creating a new task definition by myTask.json
2017/11/09 23:20:13 myService/default Registering a new task definition...
2017/11/09 23:20:13 myService/default Task definition is registered myService:4
2017/11/09 23:20:13 myService/default Updating service...
2017/11/09 23:20:13 myService/default Waiting for service stable...(it will take a few minutes)
2017/11/09 23:23:23 myService/default  PRIMARY myService:4 desired:1 pending:0 running:1
2017/11/09 23:23:29 myService/default Service is stable now. Completed!
```

### Blue/Green deployment (with AWS CodeDeploy)

`ecspresso deploy` can deploy services using the CODE_DEPLOY deployment controller. Configure ecs-service-def.json as follows.

```json
{
  "deploymentController": {
    "type": "CODE_DEPLOY"
  },
  // ...
}
```

Important notes:

- ecspresso does not create or modify any CodeDeploy resources. You must separately create an application and deployment group for your ECS service in CodeDeploy.
- ecspresso automatically detects CodeDeploy deployment settings for the ECS service.
- If there are numerous CodeDeploy applications, the API calls during this detection process may cause throttling. To mitigate this, specify the CodeDeploy application_name and deployment_group_name in the config file:

```yaml
# ecspresso.yml
codedeploy:
  application_name: myapp
  deployment_group_name: mydeployment
```

`ecspresso deploy` creates a new deployment for CodeDeploy, and it continues on CodeDeploy.

```console
$ ecspresso deploy --config ecspresso.yml --rollback-events DEPLOYMENT_FAILURE
2019/10/15 22:47:07 myService/default Starting deploy
Service: myService
Cluster: default
TaskDefinition: myService:5
TaskSets:
   PRIMARY myService:5 desired:1 pending:0 running:1
Events:
2019/10/15 22:47:08 myService/default Creating a new task definition by ecs-task-def.json
2019/10/15 22:47:08 myService/default Registering a new task definition...
2019/10/15 22:47:08 myService/default Task definition is registered myService:6
2019/10/15 22:47:08 myService/default desired count: 1
2019/10/15 22:47:09 myService/default Deployment d-XXXXXXXXX is created on CodeDeploy
2019/10/15 22:47:09 myService/default https://ap-northeast-1.console.aws.amazon.com/codesuite/codedeploy/deployments/d-XXXXXXXXX?region=ap-northeast-1
```

CodeDeploy appspec hooks can be defined in a config file. ecspresso automatically creates `Resources` and `version` elements in appspec on deployment:

```yaml
cluster: default
service: test
service_definition: ecs-service-def.json
task_definition: ecs-task-def.json
appspec:
  Hooks:
    - BeforeInstall: "LambdaFunctionToValidateBeforeInstall"
    - AfterInstall: "LambdaFunctionToValidateAfterTraffic"
    - AfterAllowTestTraffic: "LambdaFunctionToValidateAfterTestTrafficStarts"
    - BeforeAllowTraffic: "LambdaFunctionToValidateBeforeAllowingProductionTraffic"
    - AfterAllowTraffic: "LambdaFunctionToValidateAfterAllowingProductionTraffic"
```

## Scale out/in

To change the desired count of a service, specify `scale --tasks`.

```console
$ ecspresso scale --tasks 10
```

`scale` command is equivalent to `deploy --skip-task-definition --no-update-service`.

## Example of deploy

ecspresso can deploy a service using a `service_definition` JSON file.

```console
$ ecspresso deploy --config ecspresso.yml
...
```

```yaml
# ecspresso.yml
service_definition: service.json
```

service.json example:

```json
{
  "role": "ecsServiceRole",
  "desiredCount": 2,
  "loadBalancers": [
    {
      "containerName": "myLoadbalancer",
      "containerPort": 80,
      "targetGroupArn": "arn:aws:elasticloadbalancing:[region]:[account-id]:targetgroup/{target-name}/201ae83c14de522d"
    }
  ]
}
```

Keys are in the same format as `aws ecs describe-services` output.

- deploymentConfiguration
- launchType
- loadBalancers
- networkConfiguration
- placementConstraint
- placementStrategy
- role
- etc.

## Example of run task

```console
$ ecspresso run --config ecspresso.yml --task-def=db-migrate.json
```

If `--task-def` is not set, ecspresso will use the task definition included in the service.

Other options for RunTask API are set by service attributes (CapacityProviderStrategy, LaunchType, PlacementConstraints, PlacementStrategy and PlatformVersion).

## Notes

### Version constraint

`required_version` in the configuration file is for fixing the version of ecspresso.

```yaml
required_version: ">= 2.0.0, < 3"
```

This allows ecspresso to execute if the version is greater than or equal to 2.0.0 and less than 3. If the version does not fall within this range, execution will fail.

This feature is implemented by [go-version](github.com/hashicorp/go-version).

### Manage Application Auto Scaling

For ECS services using Application Auto Scaling, adjusting the minimum and maximum auto-scaling settings with the `ecspresso scale` command is a breeze. Simply specify either `scale --auto-scaling-min` or `scale --auto-scaling-max` to modify the settings.

```console
$ ecspresso scale --tasks 5 --auto-scaling-min 5 --auto-scaling-max 20
```

`ecspresso deploy` and `scale` can suspend and resume application auto scaling.

- `--suspend-auto-scaling` sets suspended state to true.
- `--resume-auto-scaling` sets suspended state to false.

To change the suspended state, simply use `ecspresso scale --suspend-auto-scaling` or `ecspresso scale --resume-auto-scaling`. These commands will only change the suspended state without affecting other settings.

### Use Jsonnet instead of JSON and YAML.

ecspresso supports the [Jsonnet](https://jsonnet.org/) file format.

- v1.7 and later: Jsonnet support for service and task definitions
- v2.0 and later: Jsonnet support for the configuration file
- v2.4 and later: supports [Jsonnet functions](#jsonnet-functions)

If a file has the `.jsonnet` extension, ecspresso will proceed in the following order:

1. process it as Jsonnet
2. convert it to JSON
3. load it with evaluation template syntax.

Using [Template syntax](#template-syntax) in Jsonnet files may lead to syntax errors due to conflicts with Jsonnet syntax. In such cases, consider using [Jsonnet functions](#jsonnet-functions) instead.

```jsonnet
{
  cluster: 'default',
  service: 'myservice',
  service_definition: 'ecs-service-def.jsonnet',
  task_definition: 'ecs-task-def.jsonnet',
}
```

ecspresso includes [github.com/google/go-jsonnet](https://github.com/google/go-jsonnet) as a library, so a separate installation of jsonnet is not needed.

`--ext-str` and `--ext-code` flag sets [Jsonnet External Variables](https://jsonnet.org/ref/stdlib.html#ext_vars).

```console
$ ecspresso --ext-str Foo=foo --ext-code "Bar=1+1" ...
```

```jsonnet
{
  foo: std.extVar('Foo'), // = "foo"
  bar: std.extVar('Bar'), // = 2
}
```

### Jsonnet functions

v2.4 and later supports Jsonnet native functions in Jsonnet files.

In the .jsonnet file,:

1. Define `local func = std.native('func');`
2. Use `func()`

Jsonnet functions are evaluated when rendering Jsonnet files, which helps avoid conflicts with template syntax.

#### `env`, `must_env`

`env` and `must_env` functions work the similary to template functions in JSON and YAML files. However, unlike template functions, Jsonnet functions are capable of rendering non-string values from environment variables using `std.parseInt()`, `std.parseJson()`, etc.

```jsonnet
local env = std.native('env');
local must_env = std.native('must_env');
{
  foo: env('FOO', 'default value'),
  bar: must_env('BAR'),
  bazNumber: std.parseInt(env('BAZ_NUMBER', '0')),
  booBool: std.parseJson(env('BOO_BOOL', 'false')),
}
```

#### Other plugin-provided functions

See [Plugins](#plugins) section.

### Deploy to Fargate

When deploying services to Fargate, both task definitions and service definitions require specific settings.

For task definitions,

- requiresCompatibilities (requires "FARGATE")
- networkMode (requires "awsvpc")
- cpu (required)
- memory (required)
- executionRoleArn (optional)

```json
{
  "taskDefinition": {
    "networkMode": "awsvpc",
    "requiresCompatibilities": [
      "FARGATE"
    ],
    "cpu": "1024",
    "memory": "2048",
    // ...
}
```

For service-definitions,

- launchType (requires "FARGATE")
- networkConfiguration (requires "awsvpcConfiguration")

```json5
{
  "launchType": "FARGATE",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "subnet-aaaaaaaa",
        "subnet-bbbbbbbb"
      ],
      "securityGroups": [
        "sg-11111111"
      ],
      "assignPublicIp": "ENABLED"
    }
  },
  // ...
}
```

### Fargate Spot support

1. Set `capacityProviders` and `defaultCapacityProviderStrategy` for the ECS cluster.
1. To migrate an existing service to use Fargate Spot, define `capacityProviderStrategy` in the service definition as shown below. Use `ecspresso deploy --update-service` to apply the settings to the service.

```json
{
  "capacityProviderStrategy": [
    {
      "base": 1,
      "capacityProvider": "FARGATE",
      "weight": 1
    },
    {
      "base": 0,
      "capacityProvider": "FARGATE_SPOT",
      "weight": 1
    }
  ],
  // ...
```

### ECS Service Connect support

ecspresso supports [ECS Service Connect](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html).

To configure, define `serviceConnectConfiguration` in service definitions and `portMappings` in task definitions.

For more details, see [Service Connect parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html#service-connect-parameters)

### EBS Volume support

ecspresso supports [Amazon EBS Volumes](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/ebs-volumes.html).

To configure, define `volumeConfigurations` in service definitions, and `mountPoints` and `volumes` in task definitions.


```json
// ecs-service-def.json
  "volumeConfigurations": [
    {
      "managedEBSVolume": {
        "filesystemType": "ext4",
        "roleArn": "arn:aws:iam::123456789012:role/ecsInfrastructureRole",
        "sizeInGiB": 10,
        "tagSpecifications": [
          {
            "propagateTags": "SERVICE",
            "resourceType": "volume"
          }
        ],
        "volumeType": "gp3"
      },
      "name": "ebs"
    }
  ]
```

```json
// ecs-task-def.json
// containerDefinitions[].mountPoints
      "mountPoints": [
        {
          "containerPath": "/mnt/ebs",
          "sourceVolume": "ebs"
        }
      ]
// volumes
  "volumes": [
    {
      "name": "ebs",
      "configuredAtLaunch": true
    }
  ]
```

`ecspresso run` command supports EBS volumes too.

By default, EBS volumes attached to standalone tasks are deleted when the task stops. Use the `--no-ebs-delete-on-termination` option to preserve volumes.

```console
$ ecspresso run --no-ebs-delete-on-termination
```

For tasks run by ECS services, EBS volumes are always deleted when the task stops. This is an ECS specification that ecspresso cannot override.


### VPC Lattice support

ecspresso supports [VPC Lattice](https://aws.amazon.com/vpc/lattice/) integration.

1. Define `portMappings` in the task definition. The `name` field is required.
```json
{
    "containerDefinitions": [
        {
            "name": "webserver",
            "portMappings": [
                {
                    "name": "web-80-tcp",
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
```

2. Define `vpcLatticeConfigurations` in the service definition. The `portName`, `roleArn`, and `targetGroupArn` fields are required.`

- The `portName` must match the `name` field of the `portMappings` in the task definition.
- The `roleArn` is the IAM role that the ECS service assumes to call the VPC Lattice API.
  - The role must have the `ecs.amazonaws.com` service principal.
  - The role should have the `AmazonECSInfrastructureRolePolicyForVpcLattice` policy or equivalent permissions.
- The `targetGroupArn` is the ARN of the VPC Lattice target group.

```json
{
  "vpcLatticeConfigurations": [
    {
      "portName": "web-80-tcp",
      "roleArn": "arn:aws:iam::123456789012:role/ecsInfrastructureRole",
      "targetGroupArn": "arn:aws:vpc-lattice:ap-northeast-1:123456789012:targetgroup/tg-009147df264a0bacb"
    }
  ],
```

ecspresso doesn't create or modify any VPC Lattice resources. You must create and associate a VPC Lattice target group with the ECS service.

See also [Use Amazon VPC Lattice to connect, observe, and secure your Amazon ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-vpc-lattice.html).

### How to check diff and verify service/task definitions before deploy.

ecspresso supports `diff` and `verify` commands.

#### diff

Shows differences between local task/service definitions and remote (on ECS) definitions.

```diff
$ ecspresso diff
--- arn:aws:ecs:ap-northeast-1:123456789012:service/ecspresso-test/nginx-local
+++ ecs-service-def.json
@@ -38,5 +38,5 @@
   },
   "placementConstraints": [],
   "placementStrategy": [],
-  "platformVersion": "1.3.0"
+  "platformVersion": "LATEST"
 }
 
--- arn:aws:ecs:ap-northeast-1:123456789012:task-definition/ecspresso-test:202
+++ ecs-task-def.json
@@ -1,6 +1,10 @@
 {
   "containerDefinitions": [
     {
       "cpu": 0,
       "environment": [],
       "essential": true,
-      "image": "nginx:latest",
+      "image": "nginx:alpine",
       "logConfiguration": {
         "logDriver": "awslogs",
         "options": {
```

v2.4 or later, `ecspresso diff --external` can invoke an external command. You can use the "diff" command you like.

For example, use [difftastic](https://github.com/Wilfred/difftastic) (`difft`) command.

```console
$ ecspresso diff --external "difft --color=always"

$ ECSPRESSO_DIFF_COMMAND="difft --color=always" ecspresso diff
```

The command should exit with status 0. If it exits with a non-zero status when two files differ (for example, `diff(1)`), you need to write a wrapper command.


#### verify

Verify resources related with service/task definitions.

For example it checks if,
- An ECS cluster exists.
- The target groups in service definitions match the container name and port defined in the definitions.
- A task role and a task execution role exist and can be assumed by ecs-tasks.amazonaws.com.
- Container images exist at the URL defined in task definitions. (Checks only for ECR or DockerHub public images.)
- Secrets in task definitions exist and are readable.
- Log streams can be created and messages can be put into the specified CloudWatch log groups streams.

ecspresso verify tries to assume the task execution role defined in task definitions to verify these items. If it fails to assume the role, it continues to verify with the current session.

```console
$ ecspresso verify
2020/12/08 11:43:10 nginx-local/ecspresso-test Starting verify
  TaskDefinition
    ExecutionRole[arn:aws:iam::123456789012:role/ecsTaskRole]
    --> [OK]
    TaskRole[arn:aws:iam::123456789012:role/ecsTaskRole]
    --> [OK]
    ContainerDefinition[nginx]
      Image[nginx:alpine]
      --> [OK]
      LogConfiguration[awslogs]
      --> [OK]
    --> [OK]
  --> [OK]
  ServiceDefinition
  --> [OK]
  Cluster
  --> [OK]
2020/12/08 11:43:14 nginx-local/ecspresso-test Verify OK!
```

### Manipulate ECS tasks

ecspresso can manipulate ECS tasks using the  `tasks` and `exec` commands.

After v2.0, These operations are provided by [ecsta](https://github.com/fujiwara/ecsta) as a library. The ecsta CLI can manipulate any ECS tasks, not limited to those deployed by ecspresso.

Consider using ecsta as a CLI command.

#### tasks

The `tasks` command lists tasks run by a service or having the same family to a task definition.

```
Flags:
      --id=                       task ID
      --output=table              output format
      --find=false                find a task from tasks list and dump it as JSON
      --stop=false                stop the task
      --force=false               stop the task without confirmation
      --trace=false               trace the task
```

The `--find` option enables task selection rom a list and displays it as JSON.

The `ECSPRESSO_FILTER_COMMAND` environment variable can be set to specify a command for filtering tasks, such as [peco](https://github.com/peco/peco), [fzf](https://github.com/junegunn/fzf), etc.

```console
$ ECSPRESSO_FILTER_COMMAND=peco ecspresso tasks --find
```

The `--stop` option allows for task selecttion and stopping from a list.

#### exec

The `exec` command executes a command on a task.

[session-manager-plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) is required in PATH.

```
Flags:
      --id=                       task ID
      --command=sh                command to execute
      --container=                container name
      --port-forward=false        enable port forward
      --local-port=0              local port number
      --port=0                    remote port number (required for --port-forward)
      --host=                     remote host (required for --port-forward)
      -L                          short expression of local-port:host:port
```

If `--id` is not set, the command shows a list of tasks to select a task to execute.

The `ECSPRESSO_FILTER_COMMAND` environment variable works the same as with the `tasks` command.

See also the official documentation [Using Amazon ECS Exec for debugging](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html).

#### port forwarding

The `--port-forward` option enables port forwarding from a local port to an ECS task's port.

```
$ ecspresso exec --port-forward --port 80 --local-port 8080
...
```

If `--id` is not set, the command shows a list of tasks to select for port forwarding.

When `--local-port` is not specified, an ephemeral port is used as the local port.

The `-L` option is a short expression for `local-port:host:port`. For example, `-L 8080:example.com:80` is equivalent to `--local-port 8080 --host example.com --port 80`.

```
$ ecspresso exec --port-forward -L 8080:example.com:80
```

## Plugins

ecspresso supports plugins to extend template functions and Jsonnet native functions.

### tfstate

The tfstate plugin introduces the `tfstate` and `tfstatef` template functions.

ecspresso.yml
```yaml
region: ap-northeast-1
cluster: default
service: test
service_definition: ecs-service-def.json
task_definition: ecs-task-def.json
plugins:
  - name: tfstate
    config:
      url: s3://my-bucket/terraform.tfstate
      # or path: terraform.tfstate    # path to local file
```

ecs-service-def.json
```json
{
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "{{ tfstatef `aws_subnet.private['%s'].id` `az-a` }}"
      ],
      "securityGroups": [
        "{{ tfstate `data.aws_security_group.default.id` }}"
      ]
    }
  }
}
```

`{{ tfstate "resource_type.resource_name.attr" }}` will expand to the attribute value of the resource in tfstate.

`{{ tfstatef "resource_type.resource_name['%s'].attr" "index" }}` is similar to `{{ tfstatef "resource_type.resource_name['index'].attr" }}`. This function is useful for build a resource addresses with environment variables.

```
{{ tfstatef `aws_subnet.ecs['%s'].id` (must_env `SERVICE`) }}
```

#### tfstate Jsonnet function

`tfstate` Jsonnet function works the same as template function in JSON and YAML files.
`tfstatef` Jsonnet function is not provided. Use `std.format()` or interpolation instead.

```jsonnet
local tfstate = std.native('tfstate');
{
  networkConfiguration: {
    awsvpcConfiguration: {
      subnets: [
        tfstate('aws_subnet.private["%s"].id' % 'az-z'),
        tfstate(std.format('aws_subnet.private["%s"].id', 'az-b')),
      ],
      securityGroups: [
        tfstate('data.aws_security_group.default.id'),
      ]
    }
  }
}
```

#### Supported tfstate URL formats

- Local file `file://path/to/terraform.tfstate`
- HTTP/HTTPS `https://example.com/terraform.tfstate`
- Amazon S3 `s3://{bucket}/{key}`
- Terraform Cloud `remote://api.terraform.io/{organization}/{workspaces}`
  - `TFE_TOKEN` environment variable is required.
- Google Cloud Storage `gs://{bucket}/{key}`
- Azure Blog Storage `azurerm://{resource_group_name}/{storage_account_name}/{container_name}/{blob_name}`

This plugin uses [tfstate-lookup](https://github.com/fujiwara/tfstate-lookup) to load tfstate.

#### Multiple tfstate support

`func_prefix` adds prefixes to template function names for each plugin configuration, enabling support for multiple tfstate files.

```yaml
# ecspresso.yml
plugins:
   - name: tfstate
     config:
       url: s3://tfstate/first.tfstate
     func_prefix: first_
   - name: tfstate
     config:
       url: s3://tfstate/second.tfstate
     func_prefix: second_
```

In templates, functions are called with the specified prefixes.

```json
[
  "{{ first_tfstate `aws_s3_bucket.main.arn` }}",
  "{{ second_tfstate `aws_s3_bucket.main.arn` }}"
]
```

Similar features are also supported for Jsonnet.

```jsonnet
local first_tfstate = std.native('first_tfstate'); // func_prefix: first_
local second_tfstate = std.native('second_tfstate'); // func_prefix: second_
[
  first_tfstate('aws_s3_bucket.main.arn'),
  second_tfstate('aws_s3_bucket.main.arn'),
]
```

### CloudFormation

The cloudformation plugin introduces the `cfn_output` and `cfn_export` template functions.

An example of a CloudFormation stack template defining Outputs and Exports.

```yaml
# StackName: ECS-ecspresso
Outputs:
  SubnetAz1:
    Value: !Ref PublicSubnetAz1
  SubnetAz2:
    Value: !Ref PublicSubnetAz2
  EcsSecurityGroupId:
    Value: !Ref EcsSecurityGroup
    Export:
      Name: !Sub ${AWS::StackName}-EcsSecurityGroupId
```

Load the cloudformation plugin in a config file.

ecspresso.yml
```yaml
# ...
plugins:
  - name: cloudformation
```

`cfn_output StackName OutputKey` looks up the OutputValue of OutputKey in the StackName.
`cfn_export ExportName` looks up the exported value by name.

ecs-service-def.json
```json
{
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "{{ cfn_output `ECS-ecspresso` `SubnetAz1` }}",
        "{{ cfn_output `ECS-ecspresso` `SubnetAz2` }}"
      ],
      "securityGroups": [
        "{{ cfn_export `ECS-ecspresso-EcsSecurityGroupId` }}"
      ]
    }
  }
}
```

#### Jsonnet functions `cfn_output`, `cfn_export`

Similar features are also supported for Jsonnet.


```jsonnet
local cfn_output = std.native('cfn_output');
local cfn_export = std.native('cfn_export');
{
  subnets: [
    cfn_output('ECS-ecspresso', 'SubnetAz1'),
    cfn_output('ECS-ecspresso', 'SubnetAz2'),
  ],
  securityGroups: [
    cfn_export('ECS-ecspresso-EcsSecurityGroupId'),
  ],
}
```

### SSM Parameter Store lookups

The `ssm` template function reads parameters from AWS Systems Manager (SSM) Parameter Store.

Given SSM Parameter Store has the following parameters:

- name: '/path/to/string', type: String, value: "ImString"
- name: '/path/to/stringlist', type: StringList, value: "ImStringList0,ImStringList1"
- name: '/path/to/securestring', type: SecureString, value: "ImSecureString"

This template,

```json
{
  "string": "{{ ssm `/path/to/string` }}",
  "stringlist": "{{ ssm `/path/to/stringlist` 1 }}",  *1
  "securestring": "{{ ssm `/path/to/securestring` }}"
}
```

will be rendered as:

```json
{
  "string": "ImString",
  "stringlist": "ImStringList1",
  "securestring": "ImSecureString"
}
```

#### Jsonnet functions `ssm`, `ssm_list`

The `ssm` function works the same as template function. For string list parameters, use `ssm_list` to specify the index.

```jsonnet
local ssm = std.native('ssm');
local ssm_list = std.native('ssm_list');
{
  string: ssm('/path/to/string'),
  stringlist: ssm_list('/path/to/stringlist', 1),
  securestring: ssm('/path/to/securestring'),
}
```

### Resolve secretsmanager secret ARN

The `secretsmanager_arn` template function resolves the Secrets Manager secret ARN by secret name.

```json
  "secrets": [
    {
      "name": "FOO",
      "valueFrom": "{{ secretsmanager_arn `foo` }}"
    }
  ]
```

will be rendered as:

```json
  "secrets": [
    {
      "name": "FOO",
      "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:foo-06XQOH"
    }
  ]
```

#### Jsonnet function `secretsmanager_arn`

The `secretsmanager_arn` function works the same as template function.

```jsonnet
local secretsmanager_arn = std.native('secretsmanager_arn');
{
  secrets: [
    {
      name: "FOO",
      valueFrom: secretsmanager_arn('foo'),
    }
  ]
}
```

## LICENSE

MIT

## Author

KAYAC Inc.
