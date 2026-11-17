# macOS 27 (Beta) auf dem ASUS ROG Strix SCAR 18 (G835LXG) – Kurzfassung

Ausführlich auf Englisch: [README.md](README.md). Baut auf dem Tahoe-Projekt
[ROG-Strix-SCAR18-G835LXG-macOS](https://github.com/saeckl/ROG-Strix-SCAR18-G835LXG-macOS) und dem
[NullMoth](https://github.com/nullmoth/nvidia-macos-driver)-Treiber auf. Getestet mit macOS 27.2 Beta (26B123) auf genau einem Gerät.

## Was funktioniert

- Start bis zum Schreibtisch – dauert 4–5 Minuten nach dem Kernel-Text (so lange Verbotszeichen).
- RTX 5090, internes Display und HDMI, Metal 4.
- **Lautsprecher, Kopfhörer, Mikrofon**: angepasster TAS2781DirectI2C 0.5.5 + VoodooHDA in der Aux-KC von macOS 27.
- **Tastaturbeleuchtung, Aura, ROG Licht, Fn-Tasten** (ASUSG835WMI per OpenCore).
- Ethernet, iPhone-Hotspot per USB.

## Was nicht geht

- **Touchpad**: VoodooI2C braucht `acpi-path`, den NullMoths A2XACPIPCI nicht setzt; nachgeliefert friert macOS 27 ein.
- **Displayhelligkeit**: Treiber meldet Erfolg, Panel reagiert nicht.
- **Setup-Assistent** stürzt ab → Konto offline anlegen ([Skript](scripts/create-user-offline.sh)).
- **Finder** stürzt ab, wenn ein Gerät dazukommt → Seitenleiste ausblenden (Ctrl+Cmd+S).

## Wichtig

- Der wichtigste Fix für den Start: `LegionI2CArrowLake.kext` darf unter Darwin 27 nicht ohne VoodooI2C geladen werden
  (MaxKernel 26.99.99 oder die ganze VoodooI2C-Gruppe auf 27.99.99).
- Die Aux-KC von macOS 27 (für VoodooHDA) muss **unter Tahoe** gebaut werden – `kmutil` liest unter 27 die UUIDs falsch.
- Schritt-für-Schritt-Liste: [docs/rebuild-checklist.md](docs/rebuild-checklist.md).
