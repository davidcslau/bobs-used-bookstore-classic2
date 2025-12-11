using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace Bookstore.Web.Controllers
{
    public class AuthenticationController : Controller
    {
        private readonly IConfiguration _configuration;

        public AuthenticationController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet]
        public async Task<IActionResult> Login(string redirectUri = null)
        {
            // For local authentication, create a simple authenticated session
            var authService = _configuration["Services:Authentication"] ?? "local";
            
            if (authService == "local")
            {
                // Create claims for local testing
                var claims = new[]
                {
                    new Claim(ClaimTypes.Name, "Local User"),
                    new Claim("sub", "local-user-123"),
                    new Claim(ClaimTypes.Email, "local@example.com")
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);

                await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, claimsPrincipal);
            }

            if (string.IsNullOrWhiteSpace(redirectUri)) 
                return RedirectToAction("Index", "Home");

            return Redirect(redirectUri);
        }

        [HttpGet]
        public async Task<IActionResult> LogOut()
        {
            var authService = _configuration["Services:Authentication"] ?? "local";
            
            if (authService == "aws")
            {
                return await CognitoSignOut();
            }
            else
            {
                return await LocalSignOut();
            }
        }

        private async Task<IActionResult> LocalSignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Index", "Home");
        }

        private async Task<IActionResult> CognitoSignOut()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            
            var domain = _configuration["Authentication:Cognito:CognitoDomain"];
            var clientId = _configuration["Authentication:Cognito:ClientId"];
            var logoutUri = $"{Request.Scheme}://{Request.Host}/";

            return Redirect($"{domain}/logout?client_id={clientId}&logout_uri={logoutUri}");
        }
    }
}
