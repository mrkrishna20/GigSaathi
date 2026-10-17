class User < ApplicationRecord
  has_secure_password

  has_many :earnings, dependent: :restrict_with_error

  before_validation :normalize_email

  validates :email, presence: true,
                    length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }
  validate :password_fits_bcrypt, if: -> { password.present? }
  validates :password_confirmation, presence: true, on: :create

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_fits_bcrypt
    return if password.bytesize <= 72

    errors.add(:password, "must be no more than 72 bytes")
  end
end
