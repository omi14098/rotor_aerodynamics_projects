function sol = forewardFlightSolver(data,solver)
    
    %----------------------------------------------------------------------
    % SOLUTION
    %----------------------------------------------------------------------
    sol = struct();
    sol.ct = zeros(solver.Sweeps*solver.NT,data.NP);
    sol.cq = zeros(solver.Sweeps*solver.NT,data.NP);
    sol.inflow_ratio = zeros(solver.Sweeps*solver.NT,data.NP);
    sol.it_required = zeros(solver.Sweeps*solver.NT);
    sol.CT = zeros(1,solver.Sweeps*solver.NT);
    sol.CQ = zeros(1,solver.Sweeps*solver.NT);
    sol.beta = zeros(1,solver.Sweeps*solver.NT+1);
    sol.dbeta = zeros(1,solver.Sweeps*solver.NT+1);
    sol.ddbeta = zeros(1,solver.Sweeps*solver.NT+1);
    sol.alfa_e = zeros(solver.Sweeps*solver.NT,data.NP);

    %----------------------------------------------------------------------
    %COMMON INPUTS
    %----------------------------------------------------------------------
    %nondimensional time for Wagner
    s = (2*data.mu./data.cr).*solver.timeMesh;
    ds = (2*data.mu./data.cr).*solver.dt;
    %helicopter mesh
    r = data.mesh;
    %Pradtl deficiency model --> sum dct up to index
    index = floor(0.97*data.NP);
    %Wagner coefficients
    A1 = 0.165;
    A2 = 0.335;
    b1 = 0.0455;
    b2 = 0.3;
    %----------------------------------------------------------------------
    %HOVERINGSOLUTION
    %----------------------------------------------------------------------
    hoveringSolution = hoveringSolver(data);   
    %----------------------------------------------------------------------
    %MEMORY ALLOCATION
    %----------------------------------------------------------------------
    Cl=zeros(1,data.NP);
    Cd=zeros(1,data.NP);
    %pitch
    theta = data.theta-data.theta1s*sin(s)+...
        -data.theta1c*cos(s);
    %wagner deficiency functions
    Xw = zeros(solver.Sweeps*solver.NT,data.NP);
    Yw = zeros(solver.Sweeps*solver.NT,data.NP);
    %----------------------------------------------------------------------
    % START THE TIME ITERATION
    %----------------------------------------------------------------------
    for n = 4:solver.NT*solver.Sweeps

        clc;
        fprintf('Computing iteration %d out of %d\n',n,...
            solver.NT*solver.Sweeps);

        psi = solver.timeMesh(n);
        err = solver.Tol+1;
        it = 0;
        l_old = hoveringSolution.InflowRatio;
        %------------------------------------------------------------------
        % START CONVERGENCE WHILE LOOP
        %------------------------------------------------------------------
        while err > solver.Tol && it < solver.ItMax
            it = it + 1;
            %--------------------------------------------------------------
            % COMPUTE THE VELOCIETIES
            %--------------------------------------------------------------
            vt = r + data.mu*sin(psi)*cos(data.alfashaft);
            vp = l_old + data.mu*sin(data.alfashaft) + data.mu*...
                cos(data.alfashaft)*cos(psi)*sin(sol.beta(n)) + ...
                data.mesh.*sol.dbeta(n);
            v = sqrt(vt.^2 + vp.^2);
            %--------------------------------------------------------------
            % AERODYNAMIC MODEL
            %--------------------------------------------------------------
            % Compute the equivalent angle of attack
            phi = atan(vp./vt);
            dalfa_e = sol.alfa_e(n,:)-sol.alfa_e(n-1,:);
            sol.alfa_e(n,:) = theta(n) + (r./v).*sol.dbeta(n) - phi;
            Xw(n,:) = exp(-b1*ds).*Xw(n-1,:) + A1.*dalfa_e...
                .*exp(-b1*0.5*ds);
            Yw(n,:) = exp(-b2*ds).*Yw(n-1,:) + A2.*dalfa_e...
                .*exp(-b2*0.5*ds);
            alfa_w = sol.alfa_e(n,:) - Xw(n,:) - Yw(n,:);
            %Compute the mach number
            M = data.Mtip .* v;
            %Equivalent lift and drag
            for i = 1:length(alfa_w)
                [cl_sect,cd_sect,~]=cpcrcm(alfa_w(i),M(i));
                Cl(i) = cl_sect;
                Cd(i) = cd_sect;
            end
            %Correction for the non circulatory part
            ddalfa_e = (sol.alfa_e(n)-2*sol.alfa_e(n-1)+sol.alfa_e(n-2))...
                ./(solver.dt^2);
            Cl = Cl + 0.5*pi*data.cr.*(dalfa_e./(solver.dt.*v)+...
                r.*sol.ddbeta(n)./(v.^2) - data.cr*0.5.*ddalfa_e./(v.^2));
            %--------------------------------------------------------------
            % BLADE ELEMENT MOMENTUM 
            %--------------------------------------------------------------
            % evaluation of the loads
            ct = real(0.5*data.solidity*(v.^2).*(cos(phi).*Cl-sin(phi).*Cd)...
                .*data.dr);
            cq = real(0.5*data.solidity*(v.^2).*(sin(phi).*Cl+cos(phi).*Cd)...
                .*data.dr);
            ct(isnan(ct)) = 0.0;
            CT = sum(ct(1:index));
            % DREES MODEL FOR THE VELOCITY DISTRIBUTION
            mux = data.mu*cos(data.alfashaft);
            muy = data.mu*sin(data.alfashaft) + l_old;
            chi = atan(mux./muy);
            kx = (4/3).*(1-cos(chi)-1.8*data.mu^2)./(sin(chi));
            ky = -2*data.mu;
            f = 1+r.*cos(psi).*kx + r.*sin(psi).*ky;
            %RECOMPUTE THE INFLOW RATIO
            err_in = solver.TolFzero+1;
            it_in = 0;
            l_old_in = l_old;
            while err_in > solver.TolFzero && it_in < solver.ItmaxFzero
                l_new = 0.5*CT.*f./sqrt((data.mu.*cos(data.alfashaft)).^2 +...
                    (data.mu*sin(data.alfashaft)+l_old_in).^2);
                err_in = norm(l_new-l_old_in);
                it_in = it_in+1;
                l_old_in = real(l_old_in + solver.DampFzero.*(l_new -l_old_in));
            end

            %--------------------------------------------------------------
            % PREPARE NEXT ITERATION 
            %--------------------------------------------------------------
            err = norm(l_old-l_new);
            l_old = real(l_old + solver.Damp.*(l_new -l_old));
        end
        %------------------------------------------------------------------
        % DYNAMIC EQUATION
        %------------------------------------------------------------------
        sol.ddbeta(n) = 3*sum((1./data.mass).*(r(1:index)-...
            data.r0).*ct(1:index)) - ...
            3*sum((data.mesh(1:index)-data.r0)...
            .*data.mesh(1:index).*sin(sol.beta(n)));
        sol.beta(n+1) = sol.beta(n) + (1.5*sol.dbeta(n)-...
            0.5*sol.dbeta(n-1))*solver.dt;
        sol.dbeta(n+1) = sol.dbeta(n) + (1.5*sol.ddbeta(n)-...
            0.5*sol.ddbeta(n-1))*solver.dt;
        %------------------------------------------------------------------
        % SAVE RESULTS
        %------------------------------------------------------------------
        sol.ct(n,:) = ct;
        sol.cq(n,:) = cq;
        sol.inflow_ratio(n,:)=l_new;
        sol.CT(n) = CT;
        sol.CQ(n) = sum(cq);
        sol.it_required(n)=it;
    end
end





%--------------------------------------------------------------------------
%DERIVATOR FUNCTIONS
% Compute the derivatives at the previous iteration
%--------------------------------------------------------------------------
function [dx] = d(x,n,h,matrix)
    if matrix
        dx = (x(n,:)-x(n-2,:))./(2*h);
    else 
        dx = (x(n)-x(n-2))./(2*h);
    end
end

function [dx] = dd(x,n,h,matrix)
    if matrix
        dx = (x(n,:)-2*x(n-1,:)+x(n-2,:))./(h*h);
    else
        dx = (x(n)-2*x(n-1)+x(n-2))./(h*h);
    end
end