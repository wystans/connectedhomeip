/*
 *   Copyright (c) 2022 Project CHIP Authors
 *   All rights reserved.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 */

#import <CHIP/CHIPError_Internal.h>

#include "../common/CHIPCommandBridge.h"
#include "PairingCommandBridge.h"
#include "PairingDelegateBridge.h"
#include "platform/PlatformManager.h"
#include <lib/support/logging/CHIPLogging.h>

using namespace ::chip;
using namespace ::chip::Controller;

void PairingCommandBridge::SetUpPairingDelegate()
{
    dispatch_queue_t callbackQueue = dispatch_queue_create("com.chip.pairing", DISPATCH_QUEUE_SERIAL);
    CHIPToolPairingDelegate * pairing = [[CHIPToolPairingDelegate alloc] init];

    pairing.deviceID = mNodeId;
    pairing.commandBridge = this;

    [CurrentCommissioner() setPairingDelegate:pairing queue:callbackQueue];
}

CHIP_ERROR PairingCommandBridge::RunCommand()
{
    NSError * error;
    CHIP_ERROR err = CHIP_NO_ERROR;
    switch (mPairingMode) {
    case PairingMode::None:
        Unpair(error);
        err = [CHIPError errorToCHIPErrorCode:error];
        SetCommandExitStatus(err);
        return err;
    case PairingMode::QRCode:
    case PairingMode::ManualCode:
        PairWithCode(error);
        break;
    case PairingMode::Ethernet:
        PairWithIPAddress(error);
        break;
    }
    err = [CHIPError errorToCHIPErrorCode:error];
    if (err != CHIP_NO_ERROR) {
        ChipLogProgress(chipTool, "Error: %s", chip::ErrorStr(err));
    }
    return err;
}

void PairingCommandBridge::PairWithCode(NSError * error)
{
    NSString * payload = [NSString stringWithUTF8String:mOnboardingPayload];

    SetUpPairingDelegate();
    [CurrentCommissioner() pairDevice:mNodeId onboardingPayload:payload error:&error];
}

void PairingCommandBridge::PairWithIPAddress(NSError * error)
{
    SetUpPairingDelegate();
    [CurrentCommissioner() pairDevice:mNodeId
                              address:[NSString stringWithUTF8String:ipAddress]
                                 port:mRemotePort
                        discriminator:mDiscriminator
                         setupPINCode:mSetupPINCode
                                error:&error];
}

void PairingCommandBridge::Unpair(NSError * error)
{
    [CurrentCommissioner() unpairDevice:mNodeId error:&error];
    NSLog(@"Upairing error: %@", error);
}
