function membPoten = simulateAdEx(params)

%membPoten = simulateAdEx(params)
%   Simulate a neuron according to the adaptive exponential model.
% 
%     INPUT:   params - a structure containing simulation parameters,
%                       with the following required fields:
% 
%              params.C      : capacitance
%              params.gl     : leak conductance
%              params.El     : leak voltage
%              params.vt     : resting membrane potential
%              params.delT   : spike width
%              params.a      : resonantor/integrator constant
%              params.tauW   : adaptation decay time
%              params.b      : adaptation jump (for updating w)
%              params.vreset : voltage reset value
%              params.simDur : simulation time in ms
%              params.dt     : integration time step in ms
%              params.input  : input current in pA
%  
% 
%    OUTPUT:   membranePotential - A vector of the neuron's membrane
%                                  potential in mV.
% 
% 
% Equations based on:
%   https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2798047/
% Read more about this model:
%   http://www.scholarpedia.org/article/Adaptive_exponential_integrate-and-fire_model
% 
% 

end % end function
