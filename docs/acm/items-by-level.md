# ACM and ACE Medical Items by Level

## Items by level

Each level carries its own column plus every column to its left.

|  | Self / buddy | CLS | Medic |
| --- | --- | --- | --- |
| ACM items to add | Pressure bandage, elastic wrap, paracetamol | Emergency trauma dressing, NPA, OPA, suction bag, chest seal, NCD kit, pulse oximeter, AED, SAM splint, Penthrox inhaler, naloxone spray, ammonia inhalant, ATNA autoinjector, midazolam autoinjector | i-gel, CricKit, ACCUVAC, BVM, pocket BVM, oxygen tank, stethoscope, thoracostomy kit, chest tube kit, pressure cuff, 16g IV, 14g IV, FAST1 IO, EZ-IO, syringes, blood bags, field blood transfusion kit, fentanyl lozenge, all 13 vials |
| ACE to keep | Tourniquet | None | Saline, plasma, epinephrine autoinjector |
| ACE to remove | Field dressing, packing bandage, elastic bandage, QuikClot, splint, morphine autoinjector, painkillers | None | Adenosine autoinjector, ACE blood bags, personal aid kit |

- ACE to keep is what the ACM wiki lists under an ACE classname.
- ACE to remove is every ACE medical item the ACM wiki does not list, plus the morphine autoinjector, which ACM uses but the unit does not issue. I have not checked the ACM source to confirm ACM disables them.
- Not decided: ACE surgical kit and suture. The wiki mentions stitching but not which item does it.
- Body bags are not treatment items and stay.

## Classnames

ACM classnames are from the ACM wiki item pages. ACE remove-list classnames are from memory of ACE3 and need checking against the installed version.

| Group | Level | Item | Classname |
| --- | --- | --- | --- |
| ACM add | Self / buddy | Pressure bandage | ACM\_PressureBandage |
| ACM add | Self / buddy | Elastic wrap | ACM\_ElasticWrap |
| ACM add | Self / buddy | Paracetamol | ACM\_Paracetamol |
| ACM add | CLS | Emergency trauma dressing | ACM\_EmergencyTraumaDressing |
| ACM add | CLS | NPA | ACM\_NPA |
| ACM add | CLS | OPA | ACM\_OPA |
| ACM add | CLS | Suction bag | ACM\_SuctionBag |
| ACM add | CLS | Chest seal | ACM\_ChestSeal |
| ACM add | CLS | NCD kit | ACM\_NCDKit |
| ACM add | CLS | Pulse oximeter | ACM\_PulseOximeter |
| ACM add | CLS | AED | ACM\_AED |
| ACM add | CLS | SAM splint | ACM\_SAMSplint |
| ACM add | CLS | Penthrox inhaler | ACM\_Inhaler\_Penthrox |
| ACM add | CLS | Naloxone spray | ACM\_Spray\_Naloxone |
| ACM add | CLS | Ammonia inhalant | ACM\_AmmoniaInhalant |
| ACM add | CLS | ATNA autoinjector | ACM\_Autoinjector\_ATNA |
| ACM add | CLS | Midazolam autoinjector | ACM\_Autoinjector\_Midazolam |
| ACM add | Medic | i-gel | ACM\_IGel |
| ACM add | Medic | CricKit | ACM\_CricKit |
| ACM add | Medic | ACCUVAC | ACM\_ACCUVAC |
| ACM add | Medic | BVM | ACM\_BVM |
| ACM add | Medic | Pocket BVM | ACM\_PocketBVM |
| ACM add | Medic | Oxygen tank | ACM\_OxygenTank\_425 |
| ACM add | Medic | Stethoscope | ACM\_Stethoscope |
| ACM add | Medic | Thoracostomy kit | ACM\_ThoracostomyKit |
| ACM add | Medic | Chest tube kit | ACM\_ChestTubeKit |
| ACM add | Medic | Pressure cuff | ACM\_PressureCuff |
| ACM add | Medic | 16g IV | ACM\_IV\_16g |
| ACM add | Medic | 14g IV | ACM\_IV\_14g |
| ACM add | Medic | FAST1 IO | ACM\_IO\_FAST |
| ACM add | Medic | EZ-IO | ACM\_IO\_EZ |
| ACM add | Medic | Syringes | ACM\_Syringe\_1, ACM\_Syringe\_3, ACM\_Syringe\_5, ACM\_Syringe\_10 |
| ACM add | Medic | Blood bags, O- | ACM\_BloodBag\_ON\_250, ACM\_BloodBag\_ON\_500, ACM\_BloodBag\_ON\_1000 |
| ACM add | Medic | Field blood transfusion kit | ACM\_FieldBloodTransfusionKit\_250, ACM\_FieldBloodTransfusionKit\_500 |
| ACM add | Medic | Fentanyl lozenge | ACM\_Lozenge\_Fentanyl |
| ACM add | Medic | Epinephrine vial | ACM\_Vial\_Epinephrine |
| ACM add | Medic | Amiodarone vial | ACM\_Vial\_Amiodarone |
| ACM add | Medic | Lidocaine vial | ACM\_Vial\_Lidocaine |
| ACM add | Medic | TXA vial | ACM\_Vial\_TXA |
| ACM add | Medic | Calcium chloride vial | ACM\_Vial\_CalciumChloride |
| ACM add | Medic | Morphine vial | ACM\_Vial\_Morphine |
| ACM add | Medic | Fentanyl vial | ACM\_Vial\_Fentanyl |
| ACM add | Medic | Ketamine vial | ACM\_Vial\_Ketamine |
| ACM add | Medic | Ondansetron vial | ACM\_Vial\_Ondansetron |
| ACM add | Medic | Ertapenem vial | ACM\_Vial\_Ertapenem |
| ACM add | Medic | Atropine vial | ACM\_Vial\_Atropine |
| ACM add | Medic | Esmolol vial | ACM\_Vial\_Esmolol |
| ACM add | Medic | Adenosine vial | ACM\_Vial\_Adenosine |
| ACE keep | Self / buddy | Tourniquet | ACE\_tourniquet |
| ACE keep | Medic | Saline | ACE\_salineIV\_250, ACE\_salineIV\_500, ACE\_salineIV |
| ACE keep | Medic | Plasma | ACE\_plasmaIV\_250, ACE\_plasmaIV\_500, ACE\_plasmaIV |
| ACE keep | Medic | Epinephrine autoinjector | ACE\_epinephrine |
| ACE remove | Self / buddy | Field dressing | ACE\_fieldDressing |
| ACE remove | Self / buddy | Packing bandage | ACE\_packingBandage |
| ACE remove | Self / buddy | Elastic bandage | ACE\_elasticBandage |
| ACE remove | Self / buddy | QuikClot | ACE\_quikclot |
| ACE remove | Self / buddy | Splint | ACE\_splint |
| ACE remove | Self / buddy | Morphine autoinjector | ACE\_morphine |
| ACE remove | Self / buddy | Painkillers | ACE\_painkillers |
| ACE remove | Medic | Adenosine autoinjector | ACE\_adenosine |
| ACE remove | Medic | ACE blood bags | ACE\_bloodIV\_250, ACE\_bloodIV\_500, ACE\_bloodIV |
| ACE remove | Medic | Personal aid kit | ACE\_personalAidKit |
| Not decided | Medic | Surgical kit | ACE\_surgicalKit |
| Not decided | Medic | Suture | ACE\_suture |

The wiki page for blood bags lists only the O- classnames. Other blood types probably follow the same pattern, but I have not confirmed their names.
