using Bookstore.Domain.Addresses;
using Bookstore.Domain.Books;
using Bookstore.Domain.Carts;
using Bookstore.Domain.Customers;
using Bookstore.Domain.Offers;
using Bookstore.Domain.Orders;
using Bookstore.Domain.ReferenceData;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
            : base(options) { }

        public DbSet<Address> Address { get; set; } = null!;

        public DbSet<Book> Book { get; set; } = null!;

        public DbSet<Customer> Customer { get; set; } = null!;

        public DbSet<Order> Order { get; set; } = null!;

        public DbSet<ShoppingCart> ShoppingCart { get; set; } = null!;

        public DbSet<OrderItem> OrderItem { get; set; } = null!;

        public DbSet<Offer> Offer { get; set; } = null!;

        public DbSet<ReferenceDataItem> ReferenceData { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Customer configuration for PostgreSQL
            modelBuilder.Entity<Customer>(entity =>
            {
                entity.Property(x => x.Sub)
                    .HasColumnType("varchar(450)")
                    .HasMaxLength(450)
                    .IsRequired();
                
                entity.HasIndex(x => x.Sub)
                    .IsUnique();
            });

            // Book relationships
            modelBuilder.Entity<Book>(entity =>
            {
                entity.HasOne(x => x.Publisher)
                    .WithMany()
                    .HasForeignKey(x => x.PublisherId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.BookType)
                    .WithMany()
                    .HasForeignKey(x => x.BookTypeId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.Genre)
                    .WithMany()
                    .HasForeignKey(x => x.GenreId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.Condition)
                    .WithMany()
                    .HasForeignKey(x => x.ConditionId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Offer relationships
            modelBuilder.Entity<Offer>(entity =>
            {
                entity.HasOne(x => x.Publisher)
                    .WithMany()
                    .HasForeignKey(x => x.PublisherId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.BookType)
                    .WithMany()
                    .HasForeignKey(x => x.BookTypeId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.Genre)
                    .WithMany()
                    .HasForeignKey(x => x.GenreId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(x => x.Condition)
                    .WithMany()
                    .HasForeignKey(x => x.ConditionId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Order relationships
            modelBuilder.Entity<Order>(entity =>
            {
                entity.HasOne(x => x.Customer)
                    .WithMany()
                    .HasForeignKey(x => x.CustomerId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Reference Data table mapping
            modelBuilder.Entity<ReferenceDataItem>()
                .ToTable("ReferenceData");

            // Shopping Cart Item composite key
            modelBuilder.Entity<ShoppingCartItem>(entity =>
            {
                entity.HasKey(x => new { x.Id, x.ShoppingCartId });
                
                entity.Property(x => x.Id)
                    .ValueGeneratedOnAdd();
            });
        }
    }
}
