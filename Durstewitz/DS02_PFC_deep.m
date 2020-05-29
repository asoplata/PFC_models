% NEURON source for 2002 PY model: ftp://ftp.cnl.salk.edu/pub/dd/pcell
% NEURON (PY,IN) and Matlab (PY only) code for 2007 model available on ModelDB
% References:
% [DS00] Durstewitz, D., Seamans, J. K., & Sejnowski, T. J. (2000). Dopamine-mediated stabilization of delay-period activity in a network model of prefrontal cortex. Journal of neurophysiology, 83(3), 1733-1750.
% [DS02] Durstewitz, D., & Seamans, J. K. (2002). The computational role of dopamine D1 receptors in working memory. Neural Networks, 15(4), 561-572.
% [DG07] Durstewitz, D., & Gabriel, T. (2007). Dynamical basis of irregular spiking in NMDA-driven prefrontal cortex neurons. Cerebral cortex, 17(4), 894-908.
% DynaSim implementation created by JSS on 11-Apr-2016, contact: sherfey@bu.edu

spec=[];

% Differences b/w [DS02] and this script: AMPA, NMDA, and GABA inputs and synapses 
% are discrete-event double exponentials in [DS02]. Here, inputs are discrete-event 
% single exponentials and synapses are continuous ODEs with (1+tanh) sigmoidal 
% fast threshold modulation. Everything else should be identical. These models 
% and [DS00] have stochastic poisson-based inputs whereas [DG07] is deterministic.

% Deep layer PFC model
Ne=100; % # pyramidal cells
Ni=37;  % # FS cells

% Input (to PY dendrite and FS cell soma)
input_type='in_vivo'; % {'in_vivo' [DS02],'in_vitro' [DG07]}
switch input_type
  case 'in_vitro' % tonic bath application of NMDAR agonist (see DG07)
    input_def={'input(V)=-gNMDA.*(1.50265./(1+0.33*exp(V./(-16)))).*V; gNMDA=0; monitor input'};
  case 'in_vivo'  % background afferent spiking that drives spontaneous spike rates observed in vivo in PFC (see DS02 and DG07)
    input_def={'input(V)=iAMPA(V)+iNMDA(V)+iGABA(V); monitor input; onset=0; offset=inf;';
               'iAMPA(V)=-gAMPA.*sAMPA(k,:).*(V-EAMPA); EAMPA=0; gAMPA=0;';
               'iNMDA(V)=-gNMDA.*sNMDA(k,:).*(1.50265./(1+0.33*exp(V./(-16)))).*(V-ENMDA); ENMDA=0; gNMDA=0;';
               'iGABA(V)=-gGABA.*sGABA(k,:).*(V-EGABA); EGABA=-75; gGABA=0;';
               'sAMPA=getPoissonGating(0,dcAMPA,0,0,0,onset,offset,tauAMPA,T,Npop); dcAMPA=0; tauAMPA=2;';
               'sNMDA=getPoissonGating(0,dcNMDA,0,0,0,onset,offset,tauNMDA,T,Npop); dcNMDA=0; tauNMDA=150;';
               'sGABA=getPoissonGating(0,dcGABA,0,0,0,onset,offset,tauGABA,T,Npop); dcGABA=0; tauGABA=5';
               };
    % input parameters for pyramidal cells
    dcAMPAe=20000;      % Hz, (4000 input neurons firing rate <FR>=5Hz)
    dcNMDAe=dcAMPAe;    % Hz
    dcGABAe=13125;      % Hz
    gAMPAe=1e-3;        % uS, AMPA->PY
    gNMDAe=gAMPAe/50;   % uS, NMDA->PY
    gGABAe=.6e-3;       % uS, GABA->PY
    % input parameters for interneurons
    dcAMPAi=dcAMPAe/2;  % Hz
    dcNMDAi=dcNMDAe/2;  % Hz
    dcGABAi=dcGABAe/2;  % Hz
    gAMPAi=.74e-3;      % uS, AMPA->FS
    gNMDAi=gAMPAi/50;   % uS, NMDA->FS
    gGABAi=.6e-3;       % uS, GABA->FS
end
state_equations=['dV/dt=(@current+input(V))./Cm; Cm=1; V(0)=-65;' input_def{:}];

% cell morphology (cylindrical compartments)
% pyramidal soma (L and diam chosen to match surface area and internal resistance with a sphere of diam 23 microns)
ls=28.618;  % um, length
ds=21.840;  % um, diameter
% pyramidal dendrite
ld=650;     % um, length
dd=6.5;     % um, diameter
% FS interneuron
li=42;      % um, length
di=42;      % um, diameter

% -------------------------------------------------------------------------
% Pyramidal cell
% -------------------------------------------------------------------------
epas=-70;     % mV, passive reversal potential
ki=140;       % mM, intracellular potassium concentration
koinf=3.82;   % mM, steady-state extracellular potassium concentration
KAF=2e6;      % potassium accumulation factor
tauK=7;       % ms, extracellular potassium decay time constant
dshellK=70e-3;% um, depth of extracellular shell for K+ diffusion
cao=2e3;      % uM?, extracellular calcium concentration
cainf=50e-3;  % uM?, steady-state intracellular calcium concentration
dshellCa=2e-4;% um, depth of intracellular shell for Ca2+ diffusion
faraday=96487;% s*A/mol, faraday constant (charge per mole of ions)

mechanism_list={'iNa','iNaP','iHVA','iDR','iKS','iKCa','CaDyn','KDyn','pas'};

% soma
l=ls; d=ds; A=d*l*pi; % um2, cylinder surface area without the ends
switch input_type
  case 'in_vitro'
    equations='dV/dt=(@current+Iapp)./Cm; Iapp=0; Cm=1; V(0)=-65';
    input_parameters={'Iapp',0};
  case 'in_vivo'
    equations=state_equations;
    input_parameters={'gAMPA',0,'dcAMPA',0,'gNMDA',0,'dcNMDA',0,'gGABA',gGABAe,'dcGABA',dcGABAe};
end
Cm=1.2e-5;            % 1.2 uF/cm2 = 1.2e-5 nF/um2
gpas=1/30e5;          % Rm=30kOhm-cm2 = 30e5 MOhm-um2, gpas=1/Rm [uS/um2]
gnaf=117e-5;          % 117 mS/cm2 = 117e-5 uS/um2
gkdr=50e-5;           % 50 mS/cm2 = 50e-5 uS/um2
gnap=1.8e-5;
gks=.08e-5;
ghva=.4e-5;
gkc=2.1e-5;
tauCa=250;            % ms, calcium decay time constant
CAF=600;              % calcium accumulation factor
VshellK=pi*dshellK*l.*(d+dshellK);    % um3, volume of shell for K+ diffusion
VshellCa=pi*dshellCa*l.*(d-dshellCa); % um3, volume of shell for Ca2+ diffusion
spec.pops(1).name='Es';
spec.pops(1).size=Ne;
spec.pops(1).equations=equations;
spec.pops(1).mechanism_list=mechanism_list;
spec.pops(1).parameters={'Cm',Cm*A,'gpas',gpas*A,'epas',epas,input_parameters{:},...
  'gnaf',gnaf*A,'gnap',gnap*A,'ghva',ghva*A,'gkdr',gkdr*A,'gks',gks*A,'gkc',gkc*A,...
  'CAF',CAF,'VshellCa',VshellCa,'cainf',cainf,'tauCa',tauCa,'cao',cao,...
  'KAF',KAF,'VshellK',VshellK,'koinf',koinf,'tauK',tauK,'ki',ki,'faraday',faraday};

% dendrite
l=ld; d=dd; A=d*l*pi; % um, cylinder surface area without the ends
switch input_type
  case 'in_vitro'
    input_parameters={'gNMDA',A*.1e-5}; %(0.05:0.003:0.25)*1e-3/100; .095e-5
  case 'in_vivo'
    input_parameters={'gAMPA',gAMPAe,'dcAMPA',dcAMPAe,'gNMDA',gNMDAe,'dcNMDA',dcNMDAe,'gGABA',gGABAe,'dcGABA',dcGABAe};
end
Cm=Cm*1.92;           % 2.304 uF/cm2
gpas=gpas*1.92;       % 1/(Rm/1.92)
gnaf=20e-5;           % 20 mS/cm2 = 20e-5 uS/um2
gkdr=14e-5;
gnap=.8e-5;
gks=.08e-5;
ghva=.8e-5;
gkc=2.1e-5;
tauCa=120;            % ms, calcium decay time constant
CAF=600;              % calcium accumulation factor
VshellK=pi*dshellK*l.*(d+dshellK);    % um3, volume of shell for K+ diffusion
VshellCa=pi*dshellCa*l.*(d-dshellCa); % um3, volume of shell for Ca2+ diffusion
spec.pops(2).name='Ed';
spec.pops(2).size=Ne;
spec.pops(2).equations=state_equations;
spec.pops(2).mechanism_list=mechanism_list;
spec.pops(2).parameters={'Cm',Cm*A,'gpas',gpas*A,'epas',epas,input_parameters{:},...
  'gnaf',gnaf*A,'gnap',gnap*A,'ghva',ghva*A,'gkdr',gkdr*A,'gks',gks*A,'gkc',gkc*A,...
  'CAF',CAF,'VshellCa',VshellCa,'cainf',cainf,'tauCa',tauCa,'cao',cao,...
  'KAF',KAF,'VshellK',VshellK,'koinf',koinf,'tauK',tauK,'ki',ki,'faraday',faraday};

% intercompartmental connections
Ri=1.5; % axial resistance [MOhm-um]
% collect relevant info
compartments={'Es' 'Ed'};
lengths     =[ls   ld];
diameters   =[ds   dd];
connections={[1 2],[2 1]};
% add connections to specification
for c=1:length(connections)
  src=connections{c}(1);
  dst=connections{c}(2);
  spec.connections(c).direction=[compartments{src} '->' compartments{dst}];
  spec.connections(c).mechanism_list={'iCOM'};
  gCOM=1/mean(Ri*4*lengths./(pi*diameters.^2));
  spec.connections(c).parameters={'gCOM',gCOM};
end

% equivalent gCOM: calculate coupling from 2 to 1:
% g12=@(r1,L1,r2,L2)(r1*r2^2)/(Ri*L1*(L1*r2^2+L2*r1^2)); % uS/um2
% gCOM=g12*(surface area)=g12*(2*pi*r1*L1)
% d->s: g12(ds/2,ls,dd/2,ld)*(pi*ls*ds)
% s->d: g12(dd/2,ld,ds/2,ls)*(pi*ld*dd)
% Note:
% [Ri]=MOhm*um, [r]=[L]=um, then [g12]=uS/um2 and [gCOM]=uS
% Ra = 1/gCOM =? length/(cross-section) = l/(pi*r^2) = 4*l/(pi*d^2)

% -------------------------------------------------------------------------
% Fast-spiking GABAergic interneuron
% -------------------------------------------------------------------------
epas=-70;     % mV, passive reversal potential
ki=140;       % mM, intracellular potassium concentration
koinf=3.82;   % mM, steady-state extracellular potassium concentration
KAF=2e6;      % potassium accumulation factor
tauK=7;       % ms, extracellular potassium decay time constant
dshellK=70e-3;% um, depth of extracellular shell for K+ diffusion
faraday=96487;% s*A/mol, faraday constant (charge per mole of ions)

% mechanisms and interneuron-specific modifications to their kinetics
mechanism_list={'iNa','iDR','KDyn','pas'};
anV0=13-10;     % 10mV more hyperpolarized than pyramidal cell
bnV0=23-10;     % 10mV more hyperpolarized than pyramidal cell
amV0=-28-10;    % 10mV more hyperpolarized than pyramidal cell
bmV0=-1-12;     % 12mV more hyperpolarized than pyramidal cell
ahV0=-43.1-10;  % 10mV more hyperpolarized than pyramidal cell
bhV0=-13.1-10;  % 10mV more hyperpolarized than pyramidal cell
hnascale=2;     % Na+ inactivation sped up 2x

% soma
l=li; d=di; A=d*l*pi; % um, cylinder surface area without the ends
switch input_type
  case 'in_vitro'
    input_parameters={'gNMDA',0}; % A*.25e-5
  case 'in_vivo'
    input_parameters={'gAMPA',gAMPAi,'dcAMPA',dcAMPAi,'gNMDA',gNMDAi,'dcNMDA',dcNMDAi,'gGABA',gGABAi,'dcGABA',dcGABAi};
end
Cm=1.2e-5;            % 1.2 uF/cm2 = 1.2e-5 nF/um2
gpas=1/30e5;          % Rm=30kOhm-cm2 = 30e5 MOhm-um2, gpas=1/Rm [uS/um2]
gnaf=45e-5;           % 45 mS/cm2 = 45-5 uS/um2
gkdr=18e-5;           % 18 mS/cm2 = 18-5 uS/um2
VshellK=pi*dshellK*l.*(d+dshellK);    % um3, volume of shell for K+ diffusion
spec.pops(3).name='FS';
spec.pops(3).size=Ni;
spec.pops(3).equations=state_equations;
spec.pops(3).mechanism_list=mechanism_list;
spec.pops(3).parameters={'Cm',Cm*A,'gpas',gpas*A,'epas',epas,input_parameters{:},...
  'gnaf',gnaf*A,'gkdr',gkdr*A,'KAF',KAF,'VshellK',VshellK,'koinf',koinf,'tauK',tauK,'ki',ki,'faraday',faraday,...
  'anV0',anV0,'bnV0',bnV0,'hnascale',hnascale,'amV0',amV0,'bmV0',bmV0,'ahV0',ahV0,'bhV0',bhV0};

% -------------------------------------------------------------------------
% Network connections
% -------------------------------------------------------------------------
% [DS00]: poisson-based input conductances were set to 5x the recurrent conductance
% [DS00]: AMPA (taur=.55,taud=2.2,E=0), NMDA (taur=10.6,taud=285,E=0), GABA (tau=1.5,E=-75)
% [DS00]: "Time constants for the AMPA and NMDA currents were taken directly from a study of glutamate receptor channels by Sprus-ton et al. (1995a)"
% tauAMPAr=.55;
% tauAMPAd=2.2;
% tauNMDAr=10.6;
% tauNMDAd=285;
% tauGABAr=.4;    % ms
% tauGABAd=1.5;   % ms
% [DS02,DG07]: AMPA (taur=.2,taud=1,E=0)   , NMDA (taur=2.3,taud=95,E=0)  , GABA (taur=.5,taud=5,E=-75)
tauAMPAr=.2;  % ms, AMPA rise time
tauAMPAd=1;   % ms, AMPA decay time
tauNMDAr=2.3; % ms, NMDA rise time
tauNMDAd=95;  % ms, NMDA decay time
tauGABAr=.5;  % ms, GABAa rise time
tauGABAd=5;   % ms, GABAa decay time
% [DS02]:
Npc=100; % # principal cells in original 2002 publication
Nin=37; % # interneurons in original 2002 publication
gAMPAee=3e-3*Npc/Ne;     % uS, PY->PY, maximal AMPA conductance
gNMDAee=gAMPAee/50;      % uS, PY->PY, maximal NMDA conductance
gGABAie=.2e-3*Nin/Ni;    % uS, FS->PY, maximal GABAa conductance
gAMPAei=.74e-3*Npc/Ne;   % uS, PY->FS
gNMDAei=gAMPAei/50;      % uS, PY->FS
gGABAii=.6e-3*Nin/Ni;    % uS, FS->FS
% inputs: (defined above)
% gAMPAe=1;      % nS, AMPA->PY
% gNMDAe=1/50;   % nS, NMDA->PY
% gGABAe=.6;     % nS, GABA->PY
% gAMPAi=.74;    % nS, AMPA->FS
% gNMDAi=.74/50; % nS, NMDA->FS
% gGABAi=.6;     % nS, GABA->FS
% [DG07]:
% gAMPA=.02;      gAMPAee=gAMPA; gAMPAei=gAMPA; % uS
% gNMDA=gAMPA/50; gNMDAee=gNMDA; gNMDAei=gNMDA; % uS
% gGABA=.006;     gGABAie=gGABA; gGABAii=gGABA; % uS

% recurrent connections b/w pyramidal cells
index=find(strcmp('Es->Ed',{spec.connections.direction}),1,'first');
spec.connections(index).mechanism_list={'iAMPA','iNMDA',spec.connections(index).mechanism_list{:}};
spec.connections(index).parameters={'gAMPA',gAMPAee,'gNMDA',gNMDAee,'EAMPA',0,'ENMDA',0,...
  'tauAMPAr',tauAMPAr,'tauAMPA',tauAMPAd,'tauNMDAr',tauNMDAr,'tauNMDA',tauNMDAd,spec.connections(index).parameters{:}};
% pyramidal<->interneuron connections
spec.connections(end+1).direction='Es->FS';
spec.connections(end).mechanism_list={'iAMPA','iNMDA'};
spec.connections(end).parameters={'gAMPA',gAMPAei,'gNMDA',gNMDAei,'EAMPA',0,'ENMDA',0,...
  'tauAMPAr',tauAMPAr,'tauAMPA',tauAMPAd,'tauNMDAr',tauNMDAr,'tauNMDA',tauNMDAd};
spec.connections(end+1).direction='FS->Es';
spec.connections(end).mechanism_list={'iGABA'};
spec.connections(end).parameters={'gGABA',gGABAie,'tauGABAr',tauGABAr,'tauGABA',tauGABAd,'EGABA',-75};
% interneuron<->interneuron connections
spec.connections(end+1).direction='FS->FS';
spec.connections(end).mechanism_list={'iGABA'};
spec.connections(end).parameters={'gGABA',gGABAii,'tauGABAr',tauGABAr,'tauGABA',tauGABAd,'EGABA',-75};

% -------------------------------------------------------------------------
% simulate model
solver_options={'tspan',[0 1000],'solver','rk2','compile_flag',1}; vary=[];
% vary={'Ed','gNMDA',[10e-7 25e-7]*dd*ld*pi;'(Es->Ed,Es->FS)','(gAMPA,gNMDA)',0;'(FS->FS,FS->Es)','gGABA',0};
% c=100; vary={'Ed','gNMDA',[25e-7]*A/c;'Es->FS','gAMPA',[0 gAMPA]/c;'FS->Es','gGABA',[0 gGABA];'Es->Ed','gAMPA',[0 gAMPA]/c};
% vary={'Es','Iapp',[.0001 .001 .01 .1 1]};
% vary={'FS','Iapp',0;'Es','Iapp',[0];'Ed','gNMDA',[0 25e-7 50e-7]*A};
% vary={'Es->FS','gAMPA',[0 gAMPA];'FS->Es','gGABA',[0 gGABA];'Es->Ed','gAMPA',[0 gAMPA]};
if 0 % synaptic blockers
  vary={'(Es->Ed,Es->FS)','(gAMPA,gNMDA)',0;'(FS->FS,FS->Es)','gGABA',0}; % turn off connections
end
if 1 % transient input to E-cells
  vary={'Ed','(dcAMPA,dcNMDA)',30e3;'(FS,Es)','(gAMPA,gNMDA,gGABA)',0;'Ed','onset',50;'Ed','offset',250}; 
end
data=dsSimulate(spec,'vary',vary,solver_options{:},'verbose_flag',1);
dsData(data,'ylim',[-100 50]);
dsData(data,'plot_type','rastergram');
% dsData(data(2),'variable',{'Es_V','Es_CaDyn_cai','Es_iKCa_c','Es_iHVA_u','Es_iHVA_w'});
% dsData(data,'variable',{'Es_V','Es_iDR_iKDR','Es_KDyn_ko','Es_iDR_EK'});
% dsData(d,'variable',{'V','IKDR','ko','EK'})


