package ecspresso

import (
	"context"
	"io"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecs/types"
)

var (
	SortTaskDefinition = sortTaskDefinition
	ToNumberCPU        = toNumberCPU
	ToNumberMemory     = toNumberMemory
	CalcDesiredCount   = calcDesiredCount
	ParseTags          = parseTags
	ExtractRoleName    = extractRoleName
	IsLongArnFormat    = isLongArnFormat
	ECRImageURLRegex   = ecrImageURLRegex
	NewLogger          = newLogger
	NewLogFilter       = newLogFilter
	NewConfigLoader    = newConfigLoader
	NewVerifier        = newVerifier
	ArnToName          = arnToName
	InitVerifyState    = initVerifyState
	VerifyResource     = verifyResource
	Map2str            = map2str
	DiffServices       = diffServices
	DiffTaskDefs       = diffTaskDefs
)

type ModifyAutoScalingParams = modifyAutoScalingParams

func (d *App) SetLogger(logger *log.Logger) {
	d.logger = logger
}

func SetLogger(logger *log.Logger) {
	commonLogger = logger
}

func SetAWSV2ConfigLoadOptionsFunc(f []func(*config.LoadOptions) error) {
	awsv2ConfigLoadOptionsFunc = f
}

func ResetAWSV2ConfigLoadOptionsFunc() {
	awsv2ConfigLoadOptionsFunc = nil
}

type TaskDefinitionForRun = taskDefinitionForRun

func (d *App) ResolveTaskDefinitionForRun(ctx context.Context, opt RunOption) (*taskDefinitionForRun, error) {
	return d.resolveTaskDefinitionForRun(ctx, opt)
}

func (opt *DiffOption) SetWriter(w io.Writer) {
	opt.w = w
}

func (i *ConfigIgnore) FilterTags(tags []types.Tag) []types.Tag {
	return i.filterTags(tags)
}
