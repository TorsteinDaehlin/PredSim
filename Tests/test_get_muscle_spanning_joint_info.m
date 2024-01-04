% --------------------------------------------------------------------------
% test_get_muscle_spanning_joint_info
%   This script tests the function "PreProcessing\get_muscle_spanning_joint_info
% 
% Original author: Lars D'Hondt
% Original date: 01/August/2022
%
% Last edit by: 
% Last edit date: 
% --------------------------------------------------------------------------

clear
close all
clc

%% preparation
% paths
[pathTests,~,~] = fileparts(mfilename('fullpath'));
[pathRepo,~,~] = fileparts(pathTests);
addpath([pathRepo '\PreProcessing'])
addpath([pathRepo '\VariousFunctions'])

load(fullfile(pathRepo,'Tests','ReferenceResults','Falisse_et_al_2022',['Falisse_et_al_2022','_paper.mat']),'R','model_info');
S = R.S;
osim_path = replace(model_info.osim_path, S.misc.main_path, pathRepo);
model_info.osim_path = osim_path;
S.subject.IG_selection = replace(S.subject.IG_selection, S.misc.main_path, pathRepo);
S.subject.IK_Bounds = replace(S.subject.IK_Bounds, S.misc.main_path, pathRepo);
S.misc.main_path = pathRepo;
S.misc.msk_geom_n_samples = 10;

[S] = getDefaultSettings(S,osim_path);


% osim_path = fullfile('C:\Users\u0150099\Downloads','CP3_T0_MRI2_arms_adapted.osim');
% load('C:\Users\u0150099\Downloads\model_info\model_info.mat','model_info','S');

% [pathHere,~,~] = fileparts(mfilename('fullpath'));
% [pathRepo,~,~] = fileparts(pathHere);
% [ResultsRepo,~,~] = fileparts(pathRepo);
% ref_file = fullfile(ResultsRepo,'PredSimResults','Fal_s1_mtp','Fal_s1_mtp_v2.mat');
% load(ref_file,'model_info','R');
% S = R.S;
% osim_path = fullfile(pathRepo,'Subjects','Fal_s1_mtp_v2','Fal_s1_mtp_v2.osim');


%% run get_muscle_spanning_joint_info
n_tests = 10;

[muscle_spanning_joint_info_1,Qs_1] = get_muscle_spanning_joint_info(S,osim_path,model_info);

muscle_spanning_joint_info_all = nan(n_tests,size(muscle_spanning_joint_info_1,1),...
    size(muscle_spanning_joint_info_1,2));
muscle_spanning_joint_info_all(1,:,:) = muscle_spanning_joint_info_1;

Qs_dummy = cell(n_tests,1);
Qs_dummy{1} = Qs_1;

for i=2:n_tests
    [muscle_spanning_joint_info_i, Qs_i] = get_muscle_spanning_joint_info(S,osim_path,model_info);
    muscle_spanning_joint_info_all(i,:,:) = muscle_spanning_joint_info_i;

    Qs_dummy{i} = Qs_i;

end

%
muscle_spanning_joint_info_sum = squeeze(sum(muscle_spanning_joint_info_all,1));

%%
isRepeatable = true;
for i=1:n_tests
    if any(muscle_spanning_joint_info_all(i,muscle_spanning_joint_info_sum>0 & muscle_spanning_joint_info_sum<n_tests))
        isRepeatable = false;
    end
end

if isRepeatable
    fprintf('The results obtained from "get_muscle_spanning_joint_info" are repeatable.\n')
else
    fprintf('The results obtained from "get_muscle_spanning_joint_info" are NOT repeatable!\n')
end

%%
% muscle_spanning_joint_info_xml_all = nan(size(muscle_spanning_joint_info_all));
% for i=1:n_tests
%     
%     [muscle_data_xml, Qs_dummy] = muscleAnalysis(S,osim_path,model_info,6);
%     muscle_spanning_joint_info_xml = squeeze(sum(abs(muscle_data_xml.dM), 1));
%     muscle_spanning_joint_info_xml(muscle_spanning_joint_info_xml<=0.0001 & muscle_spanning_joint_info_xml>=-0.0001) = 0;
%     muscle_spanning_joint_info_xml(muscle_spanning_joint_info_xml~=0) = 1;
% 
%     muscle_spanning_joint_info_xml_all(i,:,:) = muscle_spanning_joint_info_xml;
% end
% 
% muscle_spanning_joint_info_xml_sum = squeeze(sum(muscle_spanning_joint_info_xml_all,1));






