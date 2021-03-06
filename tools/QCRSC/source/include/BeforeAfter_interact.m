function [] = BeforeAfter_interact(config_filename)

%col = [51 204 255; 51 102 255; 0 46 184; 81 102 255; 91 102 255]./255;
col = colormap(colorcube);

[C] = load_config(config_filename);
[M1,D1,P1] = load_data(C);

list = P1.Properties.RowNames;

[pathstr,~,~] = fileparts(C.DataFile);

C2 = C;
filename = [pathstr,filesep,'QCRSC_',C.ProjectName,'_Data.csv'];
C2.DataFile = filename;
filename = [pathstr,filesep,'QCRSC_',C.ProjectName,'_Peak.csv'];
C2.PeakFile = filename;

if exist(filename,'file') ~= 2
    error(['Filename: ',filename,' does not exist. You need to perform QCRSC before using this utility!']);
end

[M2,D2,P2] = load_data(C2);

while 1

inval = input('Which Peak would you like to plot?','s');

if strcmpi(inval,'end') || strcmpi(inval,'quit') || strcmpi(inval,'q') || strcmpi(inval,'exit'), return; end;

peak = inval;
    
if strcmpi(peak,'R') || strcmpi(peak,'Rand')
    pp = randperm(numel(list));
    peak = list{pp(1)};
%     pp = randperm(numel(P1.Peak_Idx));
%     peak = P1.Name{pp(1)};
end

index = ismember(list,peak);

if sum(index) == 0
    display(['Fatal Error: peak ',peak,' does not exist']);
    continue;
end;

if sum(index) > 1
    display(['Fatal Error: more than one peak called',peak]);
    continue;
end;


X1 = D1.(peak);
X2 = D2.(peak);

T1 = M1.Order;
QC1 = M1.QC;
Batch1 = M1.Batch;
Label1 = cell(size(QC1));
for i = 1:numel(QC1)
    if QC1(i) == 1, Label1{i} = 'QC'; else Label1{i} = ['Batch ',num2str(Batch1(i))]; end
end

T2 = M2.Order;
QC2 = M2.QC;
Batch2 = M2.Batch;
Label2 = cell(size(QC2));
for i = 1:numel(QC1)
    if QC2(i) == 1, Label2{i} = 'QC'; else Label2{i} = ['Batch ',num2str(Batch2(i))]; end
end

if (C.zeroflag == 1)
    X1(X1 == 0) = NaN;
    X2(X2 == 0) = NaN;
end;

X11 = X1;
X22 = X2;

if strcmp(C.peakTransform,'log')
    X1 = log(X1);
    X2 = log(X2);
end;

b_num = length(unique(M1.Batch));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isnan(nansum(X1))
    display('This peak has no data')
    continue;
end
    

scrsz = get(0,'ScreenSize');
figure('Position',[(scrsz(3)*1/40) scrsz(4)/8 scrsz(3)*0.6 scrsz(4)*0.4]);
subplot(2,4,2:4)
if strcmp(C.peakTransform,'log')
    h0 = gscatter(T1(QC1),X1(QC1),Label1(QC1),'k','s',8,'off','','log(Peak Area)');
    set(h0, 'MarkerFaceColor','r');
    hold
    h = gscatter(T1(~QC1),X1(~QC1),Label1(~QC1),'k','o',8,'off','','log(Peak Area)');
    for i = 1:b_num
        set(h(i), 'MarkerFaceColor',col(i+1,:));
    end
    hold
else
    h0 = gscatter(T1(QC1),X1(QC1),Label1(QC1),'r','s',8,'off','','Peak Area');
    set(h0, 'MarkerFaceColor','r');
    hold
    h = gscatter(T1(~QC1),X1(~QC1),Label1(~QC1),'k','o',8,'off','','Peak Area');
    for i = 1:b_num
        set(h(i), 'MarkerFaceColor',col(i+1,:));
    end
    hold
end;

r = max(T1);
qcmean = nanmean(X1(QC1));
qcstd = nanstd(X1(QC1));
samplemean = nanmean(X1(~QC1));
samplestd = nanstd(X1(~QC1));

axis([min(T1)-1, max(T1)+1, min([nanmin(X1),samplemean-(2*samplestd)])*0.99, max([nanmax(X1),samplemean+(2*samplestd)])*1.01]);




title(['Peak ',peak,' : BEFORE CORRECTION']);
hold on;


plot([0,r+1]',[samplemean+(2*samplestd),samplemean+(2*samplestd)],'--k');
text(r+2,samplemean+(2*samplestd),'+2SD (Sample)');
plot([0,r+1]',[samplemean-(2*samplestd),samplemean-(2*samplestd)],'--k');
text(r+1,samplemean-(2*samplestd),'-2SD (Sample)');
plot([0,r+1]',[qcmean+(2*qcstd),qcmean+(2*qcstd)],'--b');
text(r+2,qcmean+(2*qcstd),'+2SD (QC)');
plot([0,r+1]',[qcmean-(2*qcstd),qcmean-(2*qcstd)],'--b');
text(r+2,qcmean-(2*qcstd),'-2SD (QC)');
plot([0,r+1]',[qcmean,qcmean],'--g');
plot([0,r+1]',[samplemean,samplemean],'--g');

hold off;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nansum(X2) ~= 0

subplot(2,4,6:8)

if strcmp(C.peakTransform,'log')
    h0 = gscatter(T2(QC2),X2(QC2),Label2(QC2),'k','s',8,'off','Injection Order \rightarrow','log(Peak Area)');
    set(h0, 'MarkerFaceColor','r');
    hold
    h = gscatter(T2(~QC2),X2(~QC2),Label2(~QC2),'k','o',8,'off','Injection Order \rightarrow','log(Peak Area)');
    for i = 1:b_num
        set(h(i), 'MarkerFaceColor',col(i+1,:));
    end
    hold
else
    h0 = gscatter(T2(QC2),X2(QC2),Label2(QC2),'k','s',8,'off','Injection Order \rightarrow','Peak Area');
    set(h0, 'MarkerFaceColor','r');
    hold
    h = gscatter(T2(~QC2),X2(~QC2),Label2(~QC2),'k','o',8,'off','Injection Order \rightarrow','Peak Area');
    for i = 1:b_num
        set(h(i), 'MarkerFaceColor',col(i+1,:));
    end
    hold
end;
r = max(T2);

qcmean = nanmean(X2(QC2));
qcstd = nanstd(X2(QC2));
samplemean = nanmean(X2(~QC2));
samplestd = nanstd(X2(~QC2));

axis([min(T2)-1, max(T2)+1, min([nanmin(X2),samplemean-(2*samplestd)])*0.99, max([nanmax(X2),samplemean+(2*samplestd)])*1.01]);
title(['Peak ',peak,' : AFTER CORRECTION']);
hold on;


plot([0,r+1]',[samplemean+(2*samplestd),samplemean+(2*samplestd)],'--k');
text(r+1,samplemean+(2*samplestd),'+2SD (Sample)');
plot([0,r+1]',[samplemean-(2*samplestd),samplemean-(2*samplestd)],'--k');
text(r+1,samplemean-(2*samplestd),'-2SD (Sample)');
plot([0,r+1]',[qcmean+(2*qcstd),qcmean+(2*qcstd)],'--b');
text(r+1,qcmean+(2*qcstd),'+2SD (QC)');
plot([0,r+1]',[qcmean-(2*qcstd),qcmean-(2*qcstd)],'--b');
text(r+1,qcmean-(2*qcstd),'-2SD (QC)');
plot([0,r+1]',[qcmean,qcmean],'--g');
plot([0,r+1]',[samplemean,samplemean],'--g');

hold off;

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nansum(X1(QC1)) ~= 0

%if strcmp(C.peakTransform,'log'), X1 = exp(X1); end;


X1qc = X11(QC1);
X1sample = X11(~QC1);
MPAs = nanmedian(X1sample);
MPAqc = nanmedian(X1qc);
RSD = 1.4826*100*mad(X1qc,1)/MPAqc;
D_RATIO = mad(X1sample,1)/mad(X1qc,1);


temp3 = ~isnan(X1qc);
numQCs = sum(temp3);

% This is a cludge for when the number of QCs is so low that MAD becomes
% meaningless


if numQCs < 5
    RSD = 100*nanstd(X1qc)/nanmean(X1qc);
    D_RATIO = nanstd(X1sample)/nanstd(X1qc);
end


Tqc = T1(QC1);
temp = [Tqc(2:end);Tqc(end)];
QCwindow = median((temp-Tqc)-1);

TTqc = Tqc(temp3);

leadin = floor((TTqc(1) - Tqc(1))/QCwindow);
leadout = floor((Tqc(end) - TTqc(end))/QCwindow);


if leadin > 2
    TTqc = [Tqc(1);TTqc];
end

if leadout > 2
    TTqc = [TTqc;Tqc(end)];
end


temp2 = [TTqc(2:end);TTqc(end)];
maxdist = nanmax(temp2-TTqc)-1;
MAXwindow = floor((maxdist/(QCwindow))-1);



subplot(2,4,1)
hold on;
text(0,0.8,['Peak: ',peak],'FontSize',10)
text(0,0.7,['MPA: ',num2str(MPAs,'%8.0f')],'FontSize',10)
text(0,0.6,['QCwindow: ',num2str(QCwindow)],'FontSize',10)
text(0,0.5,['MAXwindow: ',num2str(MAXwindow)],'FontSize',10)
text(0,0.4,['Total expected QCs: ',num2str(sum(QC1))],'FontSize',10)
text(0,0.3,['Total actual QCs: ',num2str(numQCs)],'FontSize',10)
text(0,0.2,['Approx. %RSD : ',num2str(RSD,'%3.1f')],'FontSize',10)
text(0,0.1,['D RATIO : ',num2str(D_RATIO,'%3.1f')],'FontSize',10)
axis off;
hold off;
else
    subplot(2,4,1)
    hold on;
    text(0,0.8,['Peak: ',peak],'FontSize',10)
    text(0,0.7,['MPA: No QCs'],'FontSize',10)
    text(0,0.6,['QCwindow: No QCs'],'FontSize',10)
    text(0,0.5,['MAXwindow: No QCs'],'FontSize',10)
    text(0,0.4,['Total expected QCs: No QCs'],'FontSize',10)
    text(0,0.3,['Total actual QCs: No QCs'],'FontSize',10)
    text(0,0.2,['Approx. %RSD : No QCs'],'FontSize',10)
    text(0,0.1,['D RATIO : No QCs'],'FontSize',10)
    axis off;
    hold off;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nansum(X2) ~= 0
%if strcmp(C.peakTransform,'log'), X2 = exp(X2); end;


X2qc = X22(QC2);
X2sample = X22(~QC2);
MPAs = nanmedian(X2sample);
MPAqc = nanmedian(X2qc);
RSD = 1.4826*100*mad(X2qc,1)/MPAqc;
D_RATIO = mad(X2sample,1)/mad(X2qc,1);

temp3 = ~isnan(X2qc);
numQCs = sum(temp3);

if numQCs < 5
    RSD = 100*std(X2qc)/nanmean(X2qc);
    D_RATIO = nanstd(X2sample)/nanstd(X2qc);
end

Tqc = T2(QC2);
temp = [Tqc(2:end);Tqc(end)];
QCwindow = median((temp-Tqc)-1);

TTqc = Tqc(temp3);

leadin = floor((TTqc(1) - Tqc(1))/QCwindow);
leadout = floor((Tqc(end) - TTqc(end))/QCwindow);


if leadin > 2
    TTqc = [Tqc(1);TTqc];
end

if leadout > 2
    TTqc = [TTqc;Tqc(end)];
end




temp2 = [TTqc(2:end);TTqc(end)];
maxdist = nanmax(temp2-TTqc)-1;
MAXwindow = floor((maxdist/(QCwindow))-1);





subplot(2,4,5)
hold on;
text(0,0.8,['Peak: ',peak],'FontSize',10)
text(0,0.7,['MPA: ',num2str(MPAs,'%8.0f')],'FontSize',10)
text(0,0.6,['QCwindow: ',num2str(QCwindow)],'FontSize',10)
text(0,0.5,['MAXwindow: ',num2str(MAXwindow)],'FontSize',10)
text(0,0.4,['Total expected QCs: ',num2str(sum(QC2))],'FontSize',10)
text(0,0.3,['Total actual QCs: ',num2str(numQCs)],'FontSize',10)
text(0,0.2,['Approx. %RSD : ',num2str(RSD,'%3.1f')],'FontSize',10)
text(0,0.1,['D RATIO : ',num2str(D_RATIO,'%3.1f')],'FontSize',10)
axis off;
hold off;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name = strsplit(filename,'.');

if C.plotflag == 1
    set(gcf, 'PaperType', 'A3');
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0.25 2.07 10.50 4.37]);
    print(gcf,'-djpeg','-r300',[pathstr,filesep,name{1},'_',peak,'_BA.jpg']);
elseif C.plotflag == 0
    reply = input('Do you want yo save this figure? Y/N [N]: ', 's');
    if strcmpi(reply,'Y')
        set(gcf, 'PaperType', 'A3');
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'inches');
        set(gcf, 'PaperPosition', [0.25 2.07 10.50 4.37]);
        print(gcf,'-djpeg','-r300',[pathstr,filesep,name{1},'_',peak,'_BA.jpg']);
    end
else
    set(gcf, 'PaperType', 'A4');
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperOrientation', 'landscape');
    set(gcf, 'PaperUnits', 'inches');
    %set(gcf, 'PaperPosition', [0.25 1.80 11.19 4.66]);
    set(gcf, 'PaperPosition', [0.25 1.80 9.5 4.66]);
    print(gcf,'-dpsc2','-r300','-append',[pathstr,filesep,ProjectName,'.ps']);
end

end
end



