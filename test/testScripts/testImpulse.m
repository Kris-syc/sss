classdef testImpulse < matlab.unittest.TestCase
    
    properties 
        pwdPath
        sysCell
        deleteBenchmarks
        testPath
    end

    methods(TestClassSetup)
        function getBenchmarks(testCase)
            testCase.pwdPath=pwd;
            if exist('benchmarksSysCell.mat','file')
                testCase.deleteBenchmarks=0;
            else
                testCase.testPath=loadBenchmarks;
                testCase.deleteBenchmarks=1;
            end
            
            temp=load('benchmarksSysCell.mat');
            testCase.sysCell=temp.benchmarksSysCell;
            if isempty(testCase.sysCell)
                error('No benchmarks loaded.');
            end
        end
    end
    
    methods(TestClassTeardown)
        function changePath(testCase)
            if testCase.deleteBenchmarks
                cd(testCase.testPath);
                delete('benchmarksSysCell.mat');
            end
            cd(testCase.pwdPath);
        end
    end
    
    %Test functions
    methods (Test)  
        function testImpulse1(testCase)
            for i=1:length(testCase.sysCell)
                sys=testCase.sysCell{i};
                t=0:0.1:5;
                
                [actH,actT]=impulse(sys,t); 
                [expH,expT]=impulse(ss(sys),t);
                         
                
                actSolution={actH,actT};
                expSolution={expH,expT};
                
                verification (testCase, actSolution, expSolution);
                verifyInstanceOf(testCase, actH , 'double', 'Instances not matching');
                verifyInstanceOf(testCase, actT , 'double', 'Instances not matching');
                verifySize(testCase, actH, size(expH), 'Size not matching');
                verifySize(testCase, actT, size(expT), 'Size not matching');

            end
        end
    end
end
    
function [] = verification (testCase, actSolution, expSolution)
          verifyEqual(testCase, actSolution, expSolution, 'RelTol', 0.1,'AbsTol',0.000001, ...
               'Difference between actual and expected exceeds relative tolerance');
end