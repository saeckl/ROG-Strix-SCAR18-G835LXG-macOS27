import plistlib, sys
path, stage = sys.argv[1], int(sys.argv[2])
ON, OFF = '27.99.99', '25.99.99'
plan = {
    0: dict(block=OFF, sky=OFF, io80211=OFF, airport=OFF),  # Tahoe only
    1: dict(block=ON, sky=ON, io80211=OFF, airport=OFF),    # Skywalk swap
    2: dict(block=ON, sky=ON, io80211=ON, airport=OFF),     # + IO80211FamilyLegacy
    3: dict(block=ON, sky=ON, io80211=ON, airport=ON),      # + AirportItlwm
}[stage]
with open(path, 'rb') as f:
    cfg = plistlib.load(f)
seen = []
add = {'IOSkywalkFamily.kext': 'sky', 'IO80211FamilyLegacy.kext': 'io80211', 'AirportItlwm.kext': 'airport'}
for k in cfg['Kernel']['Add']:
    key = add.get(k.get('BundlePath'))
    if key:
        k['MaxKernel'] = plan[key]; seen.append(key); print('  Add   %-34s -> %s' % (k['BundlePath'], plan[key]))
# AppleEthernetRL depends on Apple's IOSkywalkFamily and would hang on the RTL8125, so both are blocked together.
for b in cfg['Kernel']['Block']:
    if b.get('Identifier') in ('com.apple.iokit.IOSkywalkFamily', 'com.apple.driver.AppleEthernetRL'):
        b['MaxKernel'] = plan['block']; seen.append(b['Identifier']); print('  Block %-34s -> %s' % (b['Identifier'], plan['block']))
need = ['sky', 'io80211', 'airport', 'com.apple.iokit.IOSkywalkFamily', 'com.apple.driver.AppleEthernetRL']
if sorted(seen) != sorted(need):
    sys.exit('ERROR: expected the 5 Tahoe Wi-Fi entries, found %s. Nothing changed.' % seen)
with open(path, 'wb') as f:
    plistlib.dump(cfg, f)
