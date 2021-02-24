using CoreFoundation;
using Foundation;
using Laerdal.Xamarin.Dfu.Specific;

namespace Laerdal.Xamarin.Dfu
{
    public partial class DfuInstallation
    {
        public Laerdal.Xamarin.Dfu.iOS.DFUServiceInitiator Initiator { get; }

        public Laerdal.Xamarin.Dfu.iOS.DFUServiceController Controller { get; private set; }

        public Laerdal.Xamarin.Dfu.iOS.DFUFirmware Firmware { get; }

        private DfuProgressDelegate DfuProgressDelegate { get; }

        private DfuServiceDelegate DfuServiceDelegate { get; }

        private DfuPeripheralSelectorDelegate DfuPeripheralSelectorDelegate { get; }
        
        public DfuInstallation(string deviceId, string fileUrl) : base(deviceId, fileUrl)
        {
            DfuProgressDelegate = new DfuProgressDelegate(this);
            DfuServiceDelegate = new DfuServiceDelegate(this);
            DfuPeripheralSelectorDelegate = new DfuPeripheralSelectorDelegate(this);

            Firmware = new Laerdal.Xamarin.Dfu.iOS.DFUFirmware(new NSUrl(fileUrl, false));
            Initiator = new Laerdal.Xamarin.Dfu.iOS.DFUServiceInitiator(
                DispatchQueue.GetGlobalQueue(DispatchQueuePriority.Default), 
                DispatchQueue.GetGlobalQueue(DispatchQueuePriority.Default), 
                DispatchQueue.GetGlobalQueue(DispatchQueuePriority.Default), 
                DispatchQueue.GetGlobalQueue(DispatchQueuePriority.Default))
            {
                WeakProgressDelegate = DfuProgressDelegate,
                WeakDelegate = DfuServiceDelegate,
                Logger = new DfuLogger(),
                AlternativeAdvertisingNameEnabled = false,
                EnableUnsafeExperimentalButtonlessServiceInSecureDfu = true,
            };
            
        }

        public override void Start()
        {
            if (Controller != null)
            {
                throw new System.Exception("Controller is already set.");
            }

            Controller = Initiator.WithFirmware(Firmware).StartWithTargetWithIdentifier(new NSUuid(DeviceId));
        }

        public override void Pause()
        {
            Controller?.Pause();
        }

        public override void Resume()
        {
            Controller?.Resume();
        }

        public override void Abort()
        {
            Controller?.Abort();
        }


        public override void Dispose()
        {
            base.Dispose();
            Initiator?.Dispose();
            Controller?.Dispose();
            Firmware?.Dispose();
        }
    }
}