%Solve the full equations in the pycnocline region and plot the solution.
%Also plot leading order solutions: for \Delta \rho this is an analytic
%solution, for U, \Delta T these are numerical solutions of simplified
%equations.Presented for different values of eps1, whilst preserving asymptotic strucure
%% Preliminaries
addpath('Auxillary_functions');
figpref(4);
%% Parameters
run parameters %get dimensional parameters (brings them all into global scope)

%compute dimensionless parameters
eps1 = E0*alpha/Cd;
eps2 = E0*alpha/St;
eps3 = tau/(L/c);
eps4 = (S0 - S1)/2/S0;
delta = lt/l0;
c2 = eps2/delta;
c1 = eps1/delta;
k2 = eps2/eps1;
k3 = eps3/eps1;
k4 = eps4/eps1;
Pb = (L/c)/tau * (S0 - S1) /2 / S0 *( 1- bt*(T0 - T1)/bs / (S0 - S1));
Pt = (T0 - T1) / 2 / tau; %or Pt = (T0 - T1 + kappa1*(S0 - S1) / 2 / tau; %
kappa = (S0 + S1)/2 /S0 - bt*(L/c)/(bs *S0);
x0 = 0.3; %pycnocline position (in outer variables)
xi_max =10; %maximum value of xi (domain is -xi_max < xi < xi_max)

%% ice draft
%take linear wlog
zbF = @(X) X;
dzbF = @(X) 1 + 0*X;

%values at the pycnoclone
zb_x0 =  zbF(x0);
dzb_x0 = dzbF(x0);

%% initial conditions from below pycnocline:
%in lieu of more higher order solution below pycnocline, use as initial
%conditions on both the full equations and leading order equations
integrand    = @(x) dzbF(x).^(4/3) .*(1 - zbF(x)).^(1/3); %integrand used in analytic solution below thermocline
Q_in         = (2/3)^(3/2) * kappa^(1/2) * integral(integrand, 0, x0)^(3/2);
U_in         = (2*kappa/3)^(1/2) *integral(integrand, 0, x0)^(1/2) * dzb_x0^(1/3) * (1-zb_x0)^(1/3);
D_in         = Q_in/U_in;
delta_rho_in = U_in^2 / D_in / dzb_x0;
delta_T_in   = ((1 - zb_x0)*dzb_x0*U_in - Q_in*dzb_x0)/U_in;
Y0           = [D_in, U_in, delta_rho_in, delta_T_in];

if delta_rho_in - 2*Pb*dzb_x0 < 0 %need this to be >0
    warning('Plume becomes negatively buoynant across pycnocline (beyond region of validity of solution)')
end

%% Loop over two different values of eps1, preserving delta = O(eps1)
figure(1); clf;
eps1s = [eps1,eps1/10];
deltas = [delta, delta/10];
colmap = [0, 0, 255;
    87, 196, 80 ]/255;
lw = 2.5;       %linewidth of plots
  
for i = 1:2
    eps1 = eps1s(i);
    delta = deltas(i);
    
    %'Full' equations: including h.o.t
    rhs = @(xi,Y) forcing_full(xi,Y, Pb, delta, kappa,eps1, k3, k4,  Pt, x0,dzbF,zbF);
    M = @(xi,Y)  massmat_full(xi,Y, c1,c2);
    options = odeset('Mass',M,'RelTol', 1e-7);
    [xi,Y]  = ode15s(rhs,[-xi_max, xi_max],Y0,options);
    %extract from solution
    D         = Y(:,1);
    U         = Y(:,2);
    delta_rho = Y(:,3);
    delta_T   = Y(:,4);
    
    %velocity
    subplot(1,3,1); hold on
    %first add pycnocline box
    if i == 1
        fill([0.25, 0.4, 0.4, 0.25], [-2, -2, 2,2], [135,206,250]/255, ...
            'linestyle', 'none', 'facealpha', 0.5, 'HandleVisibility', 'off');
    end
    plot(U,xi, 'color', colmap(i,:), 'linewidth', lw);
    
    %buoyancy deficit
    subplot(1,3,2);hold on
    if i == 1
        fill([0, 0.7, 0.7, 0], [-2, -2, 2,2], [135,206,250]/255, 'linestyle', 'none', 'facealpha', 0.5);
    end
    plot(delta_rho,xi,'color', colmap(i,:),'linewidth', lw);
    
    %thermal driving
    subplot(1,3,3); hold on
    if i == 1
        fill([-0.5, 0.6, 0.6, -0.5], [-2, -2, 2,2], [135,206,250]/255, 'linestyle', 'none', 'facealpha', 0.5, 'HandleVisibility', 'off');
    end
    plot(delta_T,xi, 'color', colmap(i,:), 'linewidth', lw);
    
end

%% Asymptotic results
%Leading order equations
rhs = @(xi,Y) forcing_LO(xi,Y, Pb, Pt, dzb_x0,zb_x0);
M = @(xi,Y)  massmat_LO(xi,Y, c1,c2);
options = odeset('Mass',M, 'RelTol', 1e-7);
[xi_LO,Y_LO]  = ode15s(rhs,[-xi_max,xi_max],Y0,options);
D_LO         = Y_LO(:,1);
U_LO         = Y_LO(:,2);
delta_rho_LO = Y_LO(:,3);
delta_T_LO   = Y_LO(:,4);

% asymptotic results
Q_out =  Q_in; %you can adjust this to account for the outer evolution of Q

%numerical solution of the reduced equations
fout = @(xi, U) ((Q_in*dzb_x0*(delta_rho_in - Pb*dzb_x0*(1 + tanh(xi))) - U^3)/c1 / U/ Q_in);
[xi_A, U_A] = ode15s(fout,[-xi_max,xi_max], [U_in]);
delta_rho_A   = delta_rho_in - Pb*dzb_x0*(1 + tanh(xi_A));

%output values
delta_rho_out = delta_rho_in - 2*Pb*dzb_x0; %value of delta_rho as xi -> infty
U_out = (Q_out*dzb_x0*delta_rho_out)^(1/3);
delta_T_out = (-Q_out*dzb_x0 + U_out*dzb_x0*(1 - zb_x0 -2*Pt))/U_out;

%velocity
subplot(1,3,1); hold on
plot(U_A,xi_A, 'k--', 'linewidth', lw);
plot(U_out*ones(1,length(xi)), xi, '--','color', [170,170,170]/255 , 'linewidth', lw, 'HandleVisibility', 'off')
plot(U_in*ones(1,length(xi)), xi,'--', 'color', [170,170,170]/255,'linewidth', lw , 'HandleVisibility', 'off')
xlabel('$U$', 'interpreter', 'latex'); ylabel('$\zeta$', 'interpreter', 'latex');
box on

%buoyancy deficit
subplot(1,3,2);hold on
plot(delta_rho_A,xi_A, 'k--', 'linewidth', lw);
plot(delta_rho_in*ones(1,length(xi)), xi,'--', 'color', [170,170,170]/255, 'linewidth', lw, 'HandleVisibility', 'off')
plot(delta_rho_out*ones(1,length(xi)), xi,'--', 'color', [170,170,170]/255, 'linewidth', lw, 'HandleVisibility', 'off')
xlabel('$\Delta \rho$',  'interpreter', 'latex'); ylabel('$\zeta$',  'interpreter', 'latex');
box on
xlim([0, 0.7])

%thermal driving
subplot(1,3,3); hold on
plot(delta_T_LO,xi_LO, 'k--', 'linewidth', lw);
plot(delta_T_in*ones(1,length(xi)), xi, '--', 'color', [170,170,170]/255,'linewidth', lw, 'HandleVisibility', 'off')
plot(delta_T_out*ones(1,length(xi)), xi, 'k--','color', [170,170,170]/255, 'linewidth', lw, 'HandleVisibility', 'off')
xlabel('$\Delta T$',  'interpreter', 'latex'); ylabel('$\zeta$',  'interpreter', 'latex');
box on
xlim([-0.5, 0.6])


%% tidy
fig = gcf;
fig.Position(3:4) =  [1168 325];
subplot(1,3,1); lab{1} = text(0.21,10,'(a)', 'interpreter', 'latex', 'FontSize', 16);
subplot(1,3,2); lab{2} = text(-0.19,10,'(b)', 'interpreter', 'latex', 'FontSize', 16);
subplot(1,3,3); lab{3} = text(-0.8,10,'(c)', 'interpreter', 'latex', 'FontSize', 16);

leg= legend({'$(\epsilon_1, \delta) = (3, 0.5) \times 10^{-2}$', '$(\epsilon_1, \delta) = (3, 0.5) \times 10^{-3}$','Reduced equations'}, ...
    'Interpreter', 'latex', 'Location', 'SouthWest');

shg

subplot(1,3,1);
txtout{1} = text(0.267, 1, '$U = U_{\mathrm{out}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);
txtin{1} = text(0.355, -9, '$U = U_{\mathrm{in}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);
subplot(1,3,2)
txtout{2} = text(0.3, 2.5, '$\Delta \rho = \Delta \rho_{\mathrm{out}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);
txtin{2} = text(0.64, -9.5, '$\Delta \rho = \Delta \rho_{\mathrm{in}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);
subplot(1,3,3)
txtout{3} = text(-0.2, -4, '$\Delta T = \Delta T_{\mathrm{out}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);
txtin{3} = text(0.42, -9.5, '$\Delta T = \Delta T_{\mathrm{in}}$', 'interpreter', 'latex', 'FontSize', 16, 'Rotation', 90);

%% functions
function M = massmat_full(xi,Y, c1,c2)
%Return the mass matrix associated with one-d plume dynamics.
% Y = [d,u,r,q]
D = Y(1);
U = Y(2);
delta_rho = Y(3); %dimensionless buoyancy deficit
delta_T = Y(4); %dimensionless thermal driving

M = [U, D, 0, 0;
    c1*U^2, 2*c1*D*U,0, 0;
    U*delta_rho, D*delta_rho, D*U, 0;
    c2*U*delta_T, c2*D*delta_T, 0, c2*D*U];

end

function f = forcing_full(xi,Y, Pb, delta, kappa,eps1, k3, k4,  Pt, x0,dzbF,zbF)

%return the forcing array
D = Y(1);
U = Y(2);
delta_rho = Y(3); %dimensionless buoyancy deficit
delta_T = Y(4); %dimensionless thermal drivin

f = [delta*U*dzbF(x0 + delta*xi) + delta*eps1*k3*U*delta_T;
    D*delta_rho*dzbF(x0 + delta*xi) - U^2;
    -Pb*sech(xi)^2* D*U*dzbF(x0 + delta*xi)+ delta*U*delta_T*(kappa - k4*eps1*tanh(xi));
    -Pt*(1 + tanh(xi))*dzbF(x0 + delta*xi)*U + (1-zbF(x0 + delta*xi))*dzbF(x0 + delta*xi)*U - D*U*dzbF(x0 + delta*xi) - U*delta_T];

end

function M = massmat_LO(xi,Y, c1,c2)
%Return the mass matrix associated with one-d plume dynamics.
% Y = [d,u,r,q]
D = Y(1);
U = Y(2);
delta_rho = Y(3); %dimensionless buoyancy deficit
delta_T = Y(4); %dimensionless thermal driving

M = [U, D, 0, 0;
    c1*U^2, c1*2*D*U, 0, 0;
    U*delta_rho, D*delta_rho, D*U, 0;
    c2*U*delta_T, c2*D*delta_T, 0, c2*D*U];

end

function f = forcing_LO(xi,Y, Pb, Pt, dzb_x0,zb_x0)

%return the forcing array
D = Y(1);
U = Y(2);
delta_rho = Y(3); %dimensionless buoyancy deficit
delta_T = Y(4); %dimensionless thermal drivin

f = [0;
    D*delta_rho*dzb_x0 - U^2;
    -Pb*sech(xi)^2* D*U*dzb_x0;
    -Pt*(1 + tanh(xi))*dzb_x0*U + (1-zb_x0)*dzb_x0*U - D*U*dzb_x0 - U*delta_T];

end

