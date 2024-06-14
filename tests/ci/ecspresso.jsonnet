local must_env = std.native("must_env");
local env = std.native("env");
{
  region: "ap-northeast-1",
  cluster: "ecspresso-test",
  service: must_env("SERVICE"),
  service_definition: "ecs-service-def.jsonnet",
  task_definition: "ecs-task-def.jsonnet",
  timeout: "20m0s",
  plugins: std.prune([
    {
      name: "tfstate",
      config: {
        url: "./terraform.tfstate",
      },
      func_prefix: "local_",
    },
    if env("TFSTATE_BUCKET", "") != "" then {
      name: "tfstate",
      config: {
        url: "s3://" + env("TFSTATE_BUCKET") + "/terraform.tfstate",
      },
      func_prefix: "s3_",
    } else null,
  ])
}
