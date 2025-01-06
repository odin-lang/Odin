package objc_Metal

import NS "core:sys/darwin/Foundation"

foreign import "system:Metal.framework"

CommonCounter          :: ^NS.String
CommonCounterSet       :: ^NS.String
DeviceNotificationName :: ^NS.String
ErrorUserInfoKey       :: ^NS.ErrorUserInfoKey
ErrorDomain            :: ^NS.ErrorDomain

foreign Metal {
	@(linkage="weak") CommonCounterTimestamp:                         CommonCounter
	@(linkage="weak") CommonCounterTessellationInputPatches:          CommonCounter
	@(linkage="weak") CommonCounterVertexInvocations:                 CommonCounter
	@(linkage="weak") CommonCounterPostTessellationVertexInvocations: CommonCounter
	@(linkage="weak") CommonCounterClipperInvocations:                CommonCounter
	@(linkage="weak") CommonCounterClipperPrimitivesOut:              CommonCounter
	@(linkage="weak") CommonCounterFragmentInvocations:               CommonCounter
	@(linkage="weak") CommonCounterFragmentsPassed:                   CommonCounter
	@(linkage="weak") CommonCounterComputeKernelInvocations:          CommonCounter
	@(linkage="weak") CommonCounterTotalCycles:                       CommonCounter
	@(linkage="weak") CommonCounterVertexCycles:                      CommonCounter
	@(linkage="weak") CommonCounterTessellationCycles:                CommonCounter
	@(linkage="weak") CommonCounterPostTessellationVertexCycles:      CommonCounter
	@(linkage="weak") CommonCounterFragmentCycles:                    CommonCounter
	@(linkage="weak") CommonCounterRenderTargetWriteCycles:           CommonCounter
}

foreign Metal {
	@(linkage="weak") CommonCounterSetTimestamp:        CommonCounterSet
	@(linkage="weak") CommonCounterSetStageUtilization: CommonCounterSet
	@(linkage="weak") CommonCounterSetStatistic:        CommonCounterSet
}

foreign Metal {
	@(linkage="weak") DeviceWasAddedNotification:         DeviceNotificationName
	@(linkage="weak") DeviceRemovalRequestedNotification: DeviceNotificationName
	@(linkage="weak") DeviceWasRemovedNotification:       DeviceNotificationName
}

foreign Metal {
	@(linkage="weak") CommandBufferEncoderInfoErrorKey: ErrorUserInfoKey
}

foreign Metal {
	@(linkage="weak") IOErrorDomain: ErrorDomain
}