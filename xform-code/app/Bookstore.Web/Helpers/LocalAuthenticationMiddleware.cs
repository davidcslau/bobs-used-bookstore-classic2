using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Bookstore.Domain.Customers;
using Microsoft.AspNetCore.Http;

namespace Bookstore.Web.Helpers
{
    public class LocalAuthenticationMiddleware
    {
        private const string UserId = "FB6135C7-1464-4A72-B74E-4B63D343DD09";

        private readonly RequestDelegate _next;
        private readonly ICustomerService _customerService;

        public LocalAuthenticationMiddleware(RequestDelegate next, ICustomerService customerService)
        {
            _next = next;
            _customerService = customerService;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.Request.Path.Value?.StartsWith("/Authentication/Login") == true)
            {
                CreateClaimsPrincipal(context);

                await SaveCustomerDetailsAsync(context);

                context.Response.Cookies.Append("LocalAuthentication", "true", new CookieOptions
                {
                    Expires = DateTimeOffset.Now.AddDays(1),
                    HttpOnly = true,
                    Secure = true,
                    SameSite = SameSiteMode.Lax
                });

                context.Response.Redirect("/");
                return;
            }
            else if (context.Request.Cookies.ContainsKey("LocalAuthentication"))
            {
                CreateClaimsPrincipal(context);

                await SaveCustomerDetailsAsync(context);
            }

            await _next(context);
        }

        private void CreateClaimsPrincipal(HttpContext context)
        {
            var identity = new ClaimsIdentity("Application");

            identity.AddClaim(new Claim(ClaimTypes.Name, "bookstoreuser"));
            identity.AddClaim(new Claim("nameidentifier", UserId));
            identity.AddClaim(new Claim("sub", UserId));
            identity.AddClaim(new Claim("given_name", "Bookstore"));
            identity.AddClaim(new Claim("family_name", "User"));
            identity.AddClaim(new Claim(ClaimTypes.Role, "Administrators"));

            context.User = new ClaimsPrincipal(identity);
        }

        private async Task SaveCustomerDetailsAsync(HttpContext context)
        {
            var identity = (ClaimsIdentity?)context.User?.Identity;

            if (identity != null)
            {
                var nameIdentifier = identity.FindFirst("nameidentifier")?.Value 
                    ?? identity.FindFirst("sub")?.Value ?? UserId;
                var name = identity.Name ?? "bookstoreuser";
                var givenName = identity.FindFirst("given_name")?.Value ?? "Bookstore";
                var familyName = identity.FindFirst("family_name")?.Value ?? "User";

                var dto = new CreateOrUpdateCustomerDto(nameIdentifier, name, givenName, familyName);

                await _customerService.CreateOrUpdateCustomerAsync(dto);
            }
        }
    }
}